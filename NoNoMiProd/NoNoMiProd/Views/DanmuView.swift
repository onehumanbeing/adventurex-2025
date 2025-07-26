//
//  DanmuView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI

struct DanmuView: View {
    let text: String
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 右侧：文字和音波
            VStack(alignment: .trailing, spacing: 12) {
                // 右上角：音波动画
                HStack {
                    Spacer()
                    
                    if audioPlayer.isPlaying {
                        // 播放时：真正的音频可视化
                        DanmuWaveformView(isPlaying: audioPlayer.isPlaying, audioPlayer: audioPlayer)
                            .frame(width: 150, height: 36)
                    } else {
                        // 静音时：静态的波形条
                        HStack(spacing: 2) {
                            ForEach(0..<30, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 3, height: 6)
                            }
                        }
                        .frame(width: 150, height: 36)
                    }
                }
                
                // 下方：文字内容
                Text(text)
                    .font(.system(size: 54)) // 增加字体大小 (45 * 1.2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.5), value: text)
            }
            
            // 左侧：Logo - 移到右边，避免遮挡主视角
            AsyncImage(url: URL(string: "https://helped-monthly-alpaca.ngrok-free.app/logo.png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 168, height: 168) // 增加logo尺寸 (140 * 1.2)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 168, height: 168) // 增加占位符尺寸 (140 * 1.2)
            }
        }
        .padding(48) // 增加内边距 (40 * 1.2)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.6), Color.gray.opacity(0.3), Color.black.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: 1020) // 增加最大宽度 (850 * 1.2)
    }
}

struct DanmuWaveformView: View {
    let isPlaying: Bool
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(30, audioPlayer.audioLevels.count), id: \.self) { index in
                let level = audioPlayer.audioLevels[index]
                let height: CGFloat = max(3, CGFloat(level) * 30) // 最小3px，最大30px
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.blue)
                    .frame(width: 3, height: height)
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
        .frame(maxHeight: 30)
    }
}



#Preview {
    let audioPlayer = AudioPlayer()
    return DanmuView(
        text: "对灰绿色裤子的赞美，探讨衣物价格与购物渠道的对话。",
        audioPlayer: audioPlayer
    )
} 
