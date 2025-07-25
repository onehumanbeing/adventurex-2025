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
<<<<<<< HEAD
    private var sseBuffer = Data()
    private let segmentDuration: TimeInterval = 3.0 // 3秒分段
    private let backendURL = URL(string: "https://adventurex-2025.vercel.app/asr/stream")!
    
    // Configure URLSession with proper timeout settings
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        // Disable connection pooling to prevent socket reuse issues
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: config)
    }()

=======
    
>>>>>>> 51de91fa9fb009779d704204a6d2a73886e68093
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

<<<<<<< HEAD
    func stopListening() {
        isListening = false
        audioRecorder?.stop()
        timer?.invalidate()
        sseTask?.cancel()
        sseTask = nil
    }
    
    // 清除转录文本
    func clearTranscribedText() {
        transcribedText = ""
    }

=======
>>>>>>> 51de91fa9fb009779d704204a6d2a73886e68093
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

<<<<<<< HEAD
    private func beginSegmentedRecording() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
            transcribedText = "音频设置失败: \(error.localizedDescription)"
            return
        }
        
        recordNewSegment()
        timer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { [weak self] _ in
            self?.recordNewSegment()
        }
    }

    private func recordNewSegment() {
        audioRecorder?.stop()
        segmentIndex += 1
        let filename = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(segmentIndex).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record(forDuration: segmentDuration)
        } catch {
            print("Recording failed: \(error)")
            transcribedText = "录音失败: \(error.localizedDescription)"
=======
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
>>>>>>> 51de91fa9fb009779d704204a6d2a73886e68093
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
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file does not exist at path: \(fileURL.path)")
            return
        }
        
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        let filename = fileURL.lastPathComponent
        let mimetype = "audio/m4a"
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            let task = urlSession.uploadTask(with: request, from: data) { [weak self] responseData, response, error in
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Upload response status: \(httpResponse.statusCode)")
                }
                
                // Clean up temp file after successful upload
                DispatchQueue.global(qos: .background).async {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
            task.resume()
        } catch {
            print("Failed to read audio file: \(error)")
        }
    }

    private func startSSEStream() {
        // Cancel any existing SSE task
        sseTask?.cancel()
        sseBuffer = Data()
        
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 0 // No timeout for SSE streams
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Send empty multipart to establish SSE connection
        let data = "--\(boundary)--\r\n".data(using: .utf8)!
        
        sseTask = urlSession.uploadTask(with: request, from: data) { [weak self] data, response, error in
            if let error = error {
                print("SSE connection error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.transcribedText += "[连接错误]\n"
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("SSE response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        self?.transcribedText += "[服务器错误: \(httpResponse.statusCode)]\n"
                    }
                    return
                }
            }
            
            guard let data = data else { return }
            self?.handleSSEData(data)
        }
        
        sseTask?.resume()
    }

    private func handleSSEData(_ data: Data) {
        sseBuffer.append(data)
        
        guard let string = String(data: sseBuffer, encoding: .utf8) else { return }
        
        let lines = string.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("data: ") {
                let text = trimmedLine.replacingOccurrences(of: "data: ", with: "")
                if !text.isEmpty && text != "null" {
                    DispatchQueue.main.async {
                        self.transcribedText += text + " "
                    }
                }
            }
        }
        
        // Clear buffer if we processed complete lines
        if string.hasSuffix("\n\n") {
            sseBuffer = Data()
        }
    }
    
    deinit {
        stopListening()
    }
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 