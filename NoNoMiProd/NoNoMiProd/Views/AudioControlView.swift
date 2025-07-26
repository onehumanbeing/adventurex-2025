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
            // 播放时：正确的波浪效果
            HStack(spacing: 1) {
                ForEach(0..<25) { index in
                    WaveBarView(index: index, isPlaying: audioPlayer.isPlaying)
                }
            }
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
            // 静音时：静态的一条蓝色直线
            Rectangle()
                .fill(Color.blue)
                .frame(width: 80, height: 20) // 固定宽度和高度，与播放状态保持一致
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

struct WaveBarView: View {
    let index: Int
    let isPlaying: Bool

    var body: some View {
        let scaleY = 0.3 + sin(Double(index) * 0.4 + Date().timeIntervalSince1970 * 3) * 0.7
        return RoundedRectangle(cornerRadius: 1)
            .fill(Color.blue)
            .frame(width: 1, height: 8)
            .scaleEffect(y: scaleY)
            .animation(
                Animation.easeInOut(duration: 0.2)
                    .repeatForever()
                    .delay(Double(index) * 0.01),
                value: isPlaying
            )
    }
}

#Preview {
    AudioControlView(
        voiceURL: "https://helped-monthly-alpaca.ngrok-free.app/voice/1753466080.mp3",
        audioPlayer: AudioPlayer()
    )
} 