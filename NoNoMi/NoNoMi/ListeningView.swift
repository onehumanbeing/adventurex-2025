import SwiftUI
import AVFoundation

class ListeningViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var transcribedText = ""
    @Published var isListening = false
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var segmentIndex = 0
    private var sseTask: URLSessionDataTask?
    private var sseBuffer = Data()
    private let segmentDuration: TimeInterval = 3.0 // 3秒分段
    private let backendURL = URL(string: "http://localhost:5001/api/asr/stream")! // 修改为你的后端地址

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

    func stopListening() {
        isListening = false
        audioRecorder?.stop()
        timer?.invalidate()
        sseTask?.cancel()
    }

    private func requestMicPermissionAndStart() {
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.beginSegmentedRecording()
                } else {
                    self?.transcribedText = "麦克风权限被拒绝"
                }
            }
        }
    }

    private func beginSegmentedRecording() {
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)
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
            transcribedText = "录音失败: \(error.localizedDescription)"
        }
        // 上一段录音上传
        if segmentIndex > 1 {
            let prevFilename = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(segmentIndex-1).m4a")
            uploadAudioSegment(fileURL: prevFilename)
        } else {
            // 第一次录音时，启动SSE监听
            startSSEStream()
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

// 用于Data拼接
fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 