//
//  AudioPlayer.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import Foundation
import AVFoundation
import Accelerate

class AudioPlayer: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    
    // 备用播放器
    private var fallbackPlayer: AVAudioPlayer?
    
    @Published var isPlaying = false
    @Published var audioLevels: [Float] = Array(repeating: 0.0, count: 50) // 用于波形可视化
    
    private var displayLink: Timer?
    private var useFallback = false
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    deinit {
        stopAudio()
    }
    
    private func setupAudioEngine() {
        print("AudioPlayer: 开始设置音频引擎...")
        
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let playerNode = audioPlayerNode else { 
            print("AudioPlayer: 音频引擎或播放节点创建失败")
            return 
        }
        
        engine.attach(playerNode)
        print("AudioPlayer: 播放节点已附加到引擎")
        
        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        engine.connect(playerNode, to: mixer, format: format)
        print("AudioPlayer: 节点连接完成，格式: \(format)")
        
        // 设置音频tap来获取实时数据
        let bufferSize: AVAudioFrameCount = 1024
        mixer.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        print("AudioPlayer: 音频tap已安装")
        
        do {
            try engine.start()
            print("AudioPlayer: 音频引擎启动成功")
        } catch {
            print("AudioPlayer: 启动音频引擎失败 - \(error.localizedDescription)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // 计算音频级别（用于可视化）
        var levels: [Float] = []
        let samplesPerLevel = frameCount / audioLevels.count
        
        for i in 0..<audioLevels.count {
            let startIndex = i * samplesPerLevel
            let endIndex = min(startIndex + samplesPerLevel, frameCount)
            
            var sum: Float = 0
            for j in startIndex..<endIndex {
                sum += abs(channelData[j])
            }
            
            let average = sum / Float(endIndex - startIndex)
            levels.append(min(average * 10, 1.0)) // 放大并限制在0-1范围
        }
        
        DispatchQueue.main.async {
            self.audioLevels = levels
        }
    }
    
    func playAudio(from urlString: String) {
        print("AudioPlayer: 开始播放音频 - \(urlString)")
        
        guard !urlString.isEmpty else {
            print("AudioPlayer: 音频URL为空，跳过播放")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("AudioPlayer: 无效的音频URL - \(urlString)")
            return
        }
        
        // 停止当前播放
        stopAudio()
        
        print("AudioPlayer: 开始下载音频...")
        
        // 下载并播放音频
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("AudioPlayer: 下载音频失败 - \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("AudioPlayer: 下载的音频数据为空")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("AudioPlayer: HTTP响应状态码: \(httpResponse.statusCode)")
            }
            
            print("AudioPlayer: 音频下载成功，数据大小: \(data.count) bytes")
            
            DispatchQueue.main.async {
                self?.playAudioData(data)
            }
        }.resume()
    }
    
    private func playAudioData(_ data: Data) {
        // 如果之前AVAudioEngine失败，直接使用fallback
        if useFallback {
            playAudioDataFallback(data)
            return
        }
        
        guard let engine = audioEngine, let playerNode = audioPlayerNode else { 
            print("AudioPlayer: 音频引擎或播放节点未初始化，使用fallback")
            useFallback = true
            playAudioDataFallback(data)
            return 
        }
        
        // 检查音频引擎是否运行
        if !engine.isRunning {
            print("AudioPlayer: 音频引擎未运行，尝试启动...")
            do {
                try engine.start()
            } catch {
                print("AudioPlayer: 启动音频引擎失败，使用fallback - \(error.localizedDescription)")
                useFallback = true
                playAudioDataFallback(data)
                return
            }
        }
        
        do {
            // 创建临时文件
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tempURL)
            print("AudioPlayer: 临时文件已创建 - \(tempURL.path)")
            
            // 创建音频文件
            audioFile = try AVAudioFile(forReading: tempURL)
            print("AudioPlayer: 音频文件已创建，时长: \(audioFile?.length ?? 0) 帧")
            
            guard let file = audioFile else { 
                print("AudioPlayer: 音频文件创建失败，使用fallback")
                try? FileManager.default.removeItem(at: tempURL)
                useFallback = true
                playAudioDataFallback(data)
                return 
            }
            
            // 停止当前播放
            if playerNode.isPlaying {
                playerNode.stop()
                print("AudioPlayer: 停止之前的播放")
            }
            
            // 播放音频 - 不立即删除临时文件
            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    print("AudioPlayer: 音频播放完成")
                    self?.isPlaying = false
                    self?.audioLevels = Array(repeating: 0.0, count: 50)
                    
                    // 播放完成后清理临时文件
                    try? FileManager.default.removeItem(at: tempURL)
                    print("AudioPlayer: 临时文件已清理")
                }
            }
            
            playerNode.play()
            isPlaying = true
            
            print("AudioPlayer: 音频开始播放，isPlaying = \(isPlaying)")
            
        } catch {
            print("AudioPlayer: AVAudioEngine播放失败，使用fallback - \(error.localizedDescription)")
            useFallback = true
            playAudioDataFallback(data)
        }
    }
    
    private func playAudioDataFallback(_ data: Data) {
        print("AudioPlayer: 使用fallback播放器")
        
        do {
            fallbackPlayer = try AVAudioPlayer(data: data)
            fallbackPlayer?.delegate = self
            fallbackPlayer?.play()
            isPlaying = true
            
            // 模拟波形数据（因为fallback没有实时分析）
            simulateAudioLevels()
            
            print("AudioPlayer: Fallback播放器开始播放")
            
        } catch {
            print("AudioPlayer: Fallback播放器也失败了 - \(error.localizedDescription)")
        }
    }
    
    private func simulateAudioLevels() {
        // 模拟音频波形数据
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            var levels: [Float] = []
            for _ in 0..<50 {
                levels.append(Float.random(in: 0.1...0.8))
            }
            
            DispatchQueue.main.async {
                self.audioLevels = levels
            }
        }
        
        // 保存timer以便停止时清理
        displayLink = timer
    }
    
    // 自动播放音频
    func autoPlayAudio(from urlString: String) {
        print("AudioPlayer: 自动播放音频 - \(urlString)")
        playAudio(from: urlString)
    }
    
    func stopAudio() {
        print("AudioPlayer: 停止音频播放")
        audioPlayerNode?.stop()
        fallbackPlayer?.stop()
        fallbackPlayer = nil
        displayLink?.invalidate()
        displayLink = nil
        isPlaying = false
        audioLevels = Array(repeating: 0.0, count: 50)
        
        // 移除tap
        audioEngine?.mainMixerNode.removeTap(onBus: 0)
        
        // 重新设置tap
        if let engine = audioEngine, !useFallback {
            let mixer = engine.mainMixerNode
            let bufferSize: AVAudioFrameCount = 1024
            let format = mixer.outputFormat(forBus: 0)
            mixer.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AudioPlayer: Fallback播放器播放完成 - 成功: \(flag)")
        DispatchQueue.main.async {
            self.isPlaying = false
            self.audioLevels = Array(repeating: 0.0, count: 50)
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }
} 