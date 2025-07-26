//
//  AudioControlView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI

struct AudioControlView: View {
    let voiceURL: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        // 只显示音波动画，删除文字和图标
        if audioPlayer.isPlaying {
            // 播放时：真正的音频可视化
            WaveformView(isPlaying: audioPlayer.isPlaying, audioPlayer: audioPlayer)
                .frame(width: 80, height: 20) // 固定宽度和高度
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.6), Color.gray.opacity(0.3), Color.black.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
        } else {
            // 静音时：静态的波形条
            HStack(spacing: 1) {
                ForEach(0..<25, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 4)
                }
            }
            .frame(width: 80, height: 20)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.6), Color.gray.opacity(0.3), Color.black.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct WaveformView: View {
    let isPlaying: Bool
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<min(25, audioPlayer.audioLevels.count), id: \.self) { index in
                let level = audioPlayer.audioLevels[index]
                let height: CGFloat = max(2, CGFloat(level) * 16) // 最小2px，最大16px
                
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.blue)
                    .frame(width: 2, height: height)
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
        .frame(maxHeight: 16)
    }
}



#Preview {
    let audioPlayer = AudioPlayer()
    return AudioControlView(
        voiceURL: "https://helped-monthly-alpaca.ngrok-free.app/voice/1753466080.mp3",
        audioPlayer: audioPlayer
    )
} 