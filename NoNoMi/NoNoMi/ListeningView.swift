import SwiftUI
import AVFoundation

class ListeningViewModel: NSObject, ObservableObject {
    @Published var transcribedText = ""
    @Published var isListening = false
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var bufferList: [AVAudioPCMBuffer] = []
    private var lastSpeechTime: Date = Date()
    private var isSpeaking = false
    private var vadTimer: Timer?
    private let silenceThreshold: Float = 0.01 // 音量门限
    private let silenceDuration: TimeInterval = 0.5 // 静音超过0.5秒自动分片
    private let backendURL = URL(string: "https://adventurex-2025.vercel.app/asr/stream")!
    private var segmentIndex = 0
    private var sseTask: URLSessionDataTask?
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        transcribedText = ""
        segmentIndex = 0
        isListening = true
        requestMicPermissionAndStart()
    }

    private func requestMicPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startVADListening()
                } else {
                    self?.transcribedText = "麦克风权限被拒绝"
                    self?.isListening = false
                }
            }
        }
    }

    func stopListening() {
        isListening = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        vadTimer?.invalidate()
        sseTask?.cancel()
        bufferList.removeAll()
    }

    // 清除转录文本
    func clearTranscribedText() {
        transcribedText = ""
    }

    private func startVADListening() {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        bufferList.removeAll()
        isSpeaking = false
        lastSpeechTime = Date()
        
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let rms = self.calculateRMS(buffer: buffer)
            if rms > self.silenceThreshold {
                // 检测到说话
                if !self.isSpeaking {
                    self.isSpeaking = true
                    self.lastSpeechTime = Date()
                }
                self.lastSpeechTime = Date()
                self.bufferList.append(buffer.copy() as! AVAudioPCMBuffer)
            } else {
                // 静音
                if self.isSpeaking {
                    self.bufferList.append(buffer.copy() as! AVAudioPCMBuffer)
                }
            }
        }
        try? engine.start()
        // 启动定时器检测静音
        vadTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkSilenceAndSegment()
        }
        // 启动SSE监听
        startSSEStream()
    }

    private func checkSilenceAndSegment() {
        if isSpeaking && Date().timeIntervalSince(lastSpeechTime) > silenceDuration {
            // 静音超过阈值，分片上传
            isSpeaking = false
            segmentIndex += 1
            let filename = FileManager.default.temporaryDirectory.appendingPathComponent("vad_segment_\(segmentIndex).m4a")
            if let fileURL = writeBuffersToFile(buffers: bufferList, format: engine.inputNode.outputFormat(forBus: 0), fileURL: filename) {
                uploadAudioSegment(fileURL: fileURL)
            }
            bufferList.removeAll()
        }
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        return sqrt(sum / Float(frameLength))
    }

    private func writeBuffersToFile(buffers: [AVAudioPCMBuffer], format: AVAudioFormat, fileURL: URL) -> URL? {
        guard !buffers.isEmpty else { return nil }
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
            for buffer in buffers {
                try file.write(from: buffer)
            }
            return fileURL
        } catch {
            print("[VAD] 写入音频文件失败: \(error)")
            return nil
        }
    }

    private func uploadAudioSegment(fileURL: URL) {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var data = Data()
        let filename = fileURL.lastPathComponent
        let mimetype = "audio/m4a"
        if let fileData = try? Data(contentsOf: fileURL) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            let task = URLSession.shared.uploadTask(with: request, from: data) { _, _, _ in }
            task.resume()
        }
    }

    private func startSSEStream() {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // 发送一个空的multipart，保持连接用于SSE
        let data = "--\(boundary)--\r\n".data(using: .utf8)!
        sseTask = URLSession.shared.uploadTask(with: request, from: data) { [weak self] data, response, error in
            // 不处理响应体，SSE 由下面的 streamTask 处理
        }
        sseTask?.resume()
        // 监听SSE流
        let sseURL = backendURL
        let sseRequest = URLRequest(url: sseURL)
        let sseStreamTask = URLSession.shared.dataTask(with: sseRequest) { [weak self] data, response, error in
            guard let data = data else { return }
            self?.handleSSEData(data)
        }
        sseStreamTask.resume()
    }

    private func handleSSEData(_ data: Data) {
        guard let s = String(data: data, encoding: .utf8) else { return }
        let lines = s.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("data: ") {
                let text = line.replacingOccurrences(of: "data: ", with: "")
                DispatchQueue.main.async {
                    self.transcribedText += text + "\n"
                }
            }
        }
    }
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 