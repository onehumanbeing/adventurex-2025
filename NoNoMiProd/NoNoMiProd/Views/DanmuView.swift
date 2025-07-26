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
                        // 播放时：音波动画
                        HStack(spacing: 1) {
                            ForEach(0..<15) { index in
                                DanmuWaveBarView(index: index, isPlaying: audioPlayer.isPlaying)
                            }
                        }
                        .frame(width: 150, height: 36)
                    } else {
                        // 静音时：蓝色直线
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 150, height: 3)
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

struct DanmuWaveBarView: View {
    let index: Int
    let isPlaying: Bool

    var body: some View {
        let scaleY = 0.3 + sin(Double(index) * 0.4 + Date().timeIntervalSince1970 * 3) * 0.7
        return RoundedRectangle(cornerRadius: 1)
            .fill(Color.blue)
            .frame(width: 1, height: 6)
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
    DanmuView(text: "对灰绿色裤子的赞美，探讨衣物价格与购物渠道的对话。", audioPlayer: AudioPlayer())
} 
