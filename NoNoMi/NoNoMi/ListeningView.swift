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
        sseTask = nil
    }
    
    // 清除转录文本
    func clearTranscribedText() {
        transcribedText = ""
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

// 用于Data拼接
fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 