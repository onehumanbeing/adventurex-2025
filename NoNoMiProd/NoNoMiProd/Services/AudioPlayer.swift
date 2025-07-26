//
//  AudioPlayer.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    
    func playAudio(from urlString: String) {
        print("AudioPlayer: 开始播放音频 - \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("AudioPlayer: 无效的音频URL - \(urlString)")
            return
        }
        
        // 停止当前播放
        stopAudio()
        
        print("AudioPlayer: 开始下载音频...")
        
        // 下载并播放音频
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("AudioPlayer: 下载音频失败 - \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            print("AudioPlayer: 音频下载成功，数据大小: \(data.count) bytes")
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.play()
                    self?.isPlaying = true
                    print("AudioPlayer: 音频开始播放")
                } catch {
                    print("AudioPlayer: 播放音频失败 - \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // 自动播放音频
    func autoPlayAudio(from urlString: String) {
        print("AudioPlayer: 自动播放音频 - \(urlString)")
        playAudio(from: urlString)
    }
    
    func stopAudio() {
        print("AudioPlayer: 停止音频播放")
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AudioPlayer: 音频播放完成 - 成功: \(flag)")
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
} 