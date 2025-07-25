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
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.blue)
                        .frame(width: 1, height: 8)
                        .scaleEffect(y: 0.3 + sin(Double(index) * 0.4 + Date().timeIntervalSince1970 * 3) * 0.7)
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever()
                                .delay(Double(index) * 0.01),
                            value: audioPlayer.isPlaying
                        )
                }
            }
            .frame(width: 80, height: 20) // 固定宽度和高度
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        } else {
            // 静音时：静态的一条蓝色直线
            Rectangle()
                .fill(Color.blue)
                .frame(width: 80, height: 20) // 固定宽度和高度，与播放状态保持一致
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
    }
}

#Preview {
    AudioControlView(
        voiceURL: "https://helped-monthly-alpaca.ngrok-free.app/voice/1753466080.mp3",
        audioPlayer: AudioPlayer()
    )
} 