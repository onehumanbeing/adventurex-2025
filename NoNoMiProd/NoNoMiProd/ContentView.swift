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
    @State private var showQRWebView = false
    @State private var qrURL = ""
    
    var body: some View {
        ZStack {
            // 移除背景3D场景，让用户有更大的视野
            
            // 调整布局：将UI移到更靠近中心的位置
            VStack(alignment: .trailing, spacing: 20) { // 增加间距
                // 状态指示器 - 移到右上角但不要太靠右
                HStack {
                    Spacer()
                    
                    StatusIndicatorView(apiService: apiService)
                        .transition(.opacity.combined(with: .scale))
                }
                
                // HTML内容 - 移到右边但不要太靠右
                HStack {
                    Spacer()
                    
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
                                .font(.system(size: 29)) // 增加图标尺寸 (24 * 1.2)
                                .foregroundColor(.secondary)
                            Text("等待数据...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 300, height: 216) // 增加占位符尺寸 (250 * 1.2, 180 * 1.2)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .opacity(0.7)
                    }
                }
                
                // NoNomi（包含音波动画）- 移到右边但不要太靠右
                HStack {
                    Spacer()
                    
                    if let status = apiService.currentStatus {
                        DanmuView(text: status.danmu_text, audioPlayer: audioPlayer)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        // 显示加载状态
                        DanmuView(text: "正在连接服务器...", audioPlayer: audioPlayer)
                            .opacity(0.7)
                    }
                }
                
                // 二维码WebView - 严格显示在Danmu text下面
                if showQRWebView && !qrURL.isEmpty {
                    HStack {
                        Spacer()
                        
                        QRWebView(url: qrURL, isVisible: $showQRWebView)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40) // 增加顶部间距
            .padding(.leading, 40) // 进一步减少左边距，让UI更靠近中心
            .padding(.trailing, 70) // 增加右边距，平衡布局
            
            // 错误信息显示 - 也移到右边
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
            // 当有新数据时处理不同action
            if let status = newStatus {
                print("检测到新数据...")
                print("新状态详情: timestamp=\(status.timestamp), voice=\(status.voice), action=\(status.action)")
                
                // 检查是否为pending action
                if status.action == "pending" {
                    print("检测到pending action，播放pending音频...")
                    if !status.voice.isEmpty {
                        print("播放pending音频: \(status.voice)")
                        audioPlayer.autoPlayAudio(from: status.voice)
                    } else {
                        print("警告: pending action的voice URL为空")
                    }
                }
                // 检查是否为render action（正常完整渲染）
                else if status.action == "render" {
                    print("检测到render action，执行完整渲染...")
                    // 播放语音
                    if !status.voice.isEmpty {
                        print("播放render音频: \(status.voice)")
                        audioPlayer.autoPlayAudio(from: status.voice)
                    } else {
                        print("警告: render action的voice URL为空")
                    }
                    // Danmu和HTML Widget会自动重新渲染，因为它们绑定到status数据
                    print("Danmu和HTML Widget已重新渲染")
                }
                // 其他action或无action时，也播放语音（兼容性处理）
                else {
                    print("检测到其他action或无action，播放音频...")
                    if !status.voice.isEmpty {
                        print("开始播放音频: \(status.voice)")
                        audioPlayer.autoPlayAudio(from: status.voice)
                    } else {
                        print("警告: voice URL为空，跳过音频播放")
                    }
                }
                // 检查是否为二维码action
                else if status.action == "qr", let qrValue = status.value {
                    print("检测到二维码action，显示WebView...")
                    qrURL = qrValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showQRWebView = true
                    }
                } else {
                    // 如果不是二维码action，隐藏WebView
                    if showQRWebView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showQRWebView = false
                        }
                    }
                }
            } else {
                print("状态数据为空")
            }
        }
        .onDisappear {
            print("NoNoMiProd 应用关闭，停止轮询...")
            apiService.stopPolling()
            audioPlayer.stopAudio()
        }
        .animation(.easeInOut(duration: 0.3), value: apiService.currentStatus)
        .animation(.easeInOut(duration: 0.3), value: apiService.error)
        .animation(.easeInOut(duration: 0.3), value: showQRWebView)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
