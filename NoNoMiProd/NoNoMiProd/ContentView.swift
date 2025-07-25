//
//  ContentView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject private var apiService = APIService()
    @StateObject private var audioPlayer = AudioPlayer()
    
    var body: some View {
        ZStack {
            // 移除背景3D场景，让用户有更大的视野
            
            // 左侧紧凑布局：所有视图都在左边
            VStack(alignment: .leading, spacing: 12) {
                // 状态指示器
                HStack {
                    StatusIndicatorView(apiService: apiService)
                        .transition(.opacity.combined(with: .scale))
                    
                    Spacer()
                }
                
                // HTML内容
                HStack {
                    if let status = apiService.currentStatus {
                        HTMLWidgetView(
                            html: status.html,
                            width: status.width,
                            height: status.height
                        )
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        // 显示占位符
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            Text("等待数据...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 200, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .opacity(0.7)
                    }
                    
                    Spacer()
                }
                
                // NoNomi（包含音波动画）
                HStack {
                    if let status = apiService.currentStatus {
                        DanmuView(text: status.danmu_text, audioPlayer: audioPlayer)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        // 显示加载状态
                        DanmuView(text: "正在连接服务器...", audioPlayer: audioPlayer)
                            .opacity(0.7)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
            // 错误信息显示
            if let error = apiService.error {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text("连接错误")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .frame(maxWidth: 300)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            print("NoNoMiProd 应用启动，开始轮询API...")
            apiService.startPolling()
        }
        .onChange(of: apiService.currentStatus) { newStatus in
            // 当有新数据时自动播放音频
            if let status = newStatus {
                print("检测到新数据，自动播放音频...")
                audioPlayer.autoPlayAudio(from: status.voice)
            }
        }
        .onDisappear {
            print("NoNoMiProd 应用关闭，停止轮询...")
            apiService.stopPolling()
            audioPlayer.stopAudio()
        }
        .animation(.easeInOut(duration: 0.3), value: apiService.currentStatus)
        .animation(.easeInOut(duration: 0.3), value: apiService.error)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
