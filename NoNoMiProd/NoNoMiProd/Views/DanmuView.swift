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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                
                Text("NoNomi")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 音波动画在右上角
                if audioPlayer.isPlaying {
                    // 播放时：音波动画
                    HStack(spacing: 1) {
                        ForEach(0..<15) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.blue)
                                .frame(width: 1, height: 6)
                                .scaleEffect(y: 0.3 + sin(Double(index) * 0.4 + Date().timeIntervalSince1970 * 3) * 0.7)
                                .animation(
                                    Animation.easeInOut(duration: 0.2)
                                        .repeatForever()
                                        .delay(Double(index) * 0.01),
                                    value: audioPlayer.isPlaying
                                )
                        }
                    }
                    .frame(width: 50, height: 12)
                } else {
                    // 静音时：蓝色直线
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 1)
                }
            }
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .leading)))
                .animation(.easeInOut(duration: 0.5), value: text)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(maxWidth: 250)
    }
}

#Preview {
    DanmuView(text: "对灰绿色裤子的赞美，探讨衣物价格与购物渠道的对话。", audioPlayer: AudioPlayer())
} 
