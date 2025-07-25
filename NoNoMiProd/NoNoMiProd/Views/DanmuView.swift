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
            // 左侧：Logo
            AsyncImage(url: URL(string: "https://helped-monthly-alpaca.ngrok-free.app/logo.png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
            }
            
            // 右侧：文字和音波
            VStack(alignment: .trailing, spacing: 12) {
                // 右上角：音波动画
                HStack {
                    Spacer()
                    
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
                    .font(.system(size: 39))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.5), value: text)
            }
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(maxWidth: 750)
    }
}

#Preview {
    DanmuView(text: "对灰绿色裤子的赞美，探讨衣物价格与购物渠道的对话。", audioPlayer: AudioPlayer())
} 
