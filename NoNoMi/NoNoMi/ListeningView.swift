import SwiftUI
import AVFoundation

class ListeningViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var transcribedText = ""
    @Published var isListening = false
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var segmentIndex = 0
    private let segmentDuration: TimeInterval = 3.0 // 3秒分段
    
    // 存储所有分片转写结果，便于长语音拼接
    private var segmentResults: [Int: String] = [:]

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        print("[ListeningViewModel] startListening called")
        transcribedText = ""
        segmentIndex = 0
        segmentResults.removeAll()
        isListening = true
        requestMicPermissionAndStart()
    }

    func stopListening() {
        print("[ListeningViewModel] stopListening called")
        isListening = false
        audioRecorder?.stop()
        timer?.invalidate()
    }
    
    // 清除转录文本
    func clearTranscribedText() {
        transcribedText = ""
        segmentResults.removeAll()
    }

    private func requestMicPermissionAndStart() {
        print("[ListeningViewModel] requestMicPermissionAndStart called")
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                print("[ListeningViewModel] requestRecordPermission granted: \(granted)")
                if granted {
                    self?.beginSegmentedRecording()
                } else {
                    self?.transcribedText = "麦克风权限被拒绝"
                    self?.isListening = false
                }
            }
        }
    }

    private func beginSegmentedRecording() {
        print("[ListeningViewModel] beginSegmentedRecording called")
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
        
        // 处理上一段录音
        if segmentIndex > 1 {
            let prevFilename = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(segmentIndex-1).m4a")
            processAudioSegment(fileURL: prevFilename)
        }
    }

    // 从 Info.plist 读取硅流API Key
    private var siliconflowApiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "SiliconFlowAPIKey") as? String
    }

    private func processAudioSegment(fileURL: URL) {
        guard let audioData = try? Data(contentsOf: fileURL) else {
            let msg = "[ASR] 读取音频文件失败"
            print(msg)
            DispatchQueue.main.async {
                self.transcribedText += msg + "\n"
            }
            return
        }
        
        guard let apiKey = siliconflowApiKey, !apiKey.isEmpty else {
            let msg = "[配置错误] 未设置硅流API Key，请在Info.plist中添加 SiliconFlowAPIKey"
            print(msg)
            DispatchQueue.main.async {
                self.transcribedText += msg + "\n"
            }
            return
        }
        
        let currentSegment = segmentIndex - 1 // 当前处理的是上一个分片
        print("[ASR] 使用SiliconFlow服务转写分片 \(currentSegment)")
        
        SiliconFlowASRService.shared.transcribe(
            audioData: audioData,
            fileName: fileURL.lastPathComponent,
            apiKey: apiKey
        ) { [weak self] text, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.segmentResults[currentSegment] = text
                    print("[ASR] 分片\(currentSegment)转写成功: \(text)")
                } else if let error = error {
                    let errMsg = "[转写失败] 分片\(currentSegment)：\(error.localizedDescription)"
                    self.segmentResults[currentSegment] = errMsg
                    print(errMsg)
                } else {
                    let errMsg = "[转写失败] 分片\(currentSegment)：未知错误"
                    self.segmentResults[currentSegment] = errMsg
                    print(errMsg)
                }
                // 拼接所有分片，按顺序展示
                self.updateTranscribedText()
            }
        }
        
        // 清理临时文件
        DispatchQueue.global(qos: .background).async {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func updateTranscribedText() {
        let sortedKeys = segmentResults.keys.sorted()
        let merged = sortedKeys.compactMap { segmentResults[$0] }.joined(separator: " ")
        transcribedText = merged
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