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
        guard let url = URL(string: urlString) else {
            print("Invalid audio URL")
            return
        }
        
        // 停止当前播放
        stopAudio()
        
        // 下载并播放音频
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Failed to download audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.play()
                    self?.isPlaying = true
                } catch {
                    print("Failed to play audio: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // 自动播放音频
    func autoPlayAudio(from urlString: String) {
        playAudio(from: urlString)
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
} 