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
    @StateObject private var walletService = CryptoWalletService()
    @State private var showQRWebView = false
    @State private var qrURL = ""
    @State private var showTransferView = false
    @State private var transferChain: CryptoChain = .injective
    
    var body: some View {
        ZStack {
            // 移除背景3D场景，让用户有更大的视野
            

            
            // 悬浮转账按钮 - 调整位置避免遮挡QRWebView
            if showTransferView {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        TransferFloatingView(chain: transferChain, walletService: walletService)
                            .offset(x: 200, y: 0) // 向右偏移避免遮挡左侧的QRWebView
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // 调整布局：将UI移到更靠左的位置
            VStack(alignment: .leading, spacing: 20) { // 改为左对齐
                // 状态指示器 - 移到左上角
                StatusIndicatorView(apiService: apiService)
                    .transition(.opacity.combined(with: .scale))
                
                // HTML内容 - 移到左边
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
                    .opacity(0.7)
                }
                
                // NoNomi（包含音波动画）- 移到左边
                if let status = apiService.currentStatus {
                    DanmuView(text: status.danmu_text, audioPlayer: audioPlayer)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    // 显示加载状态
                    DanmuView(text: "正在连接服务器...", audioPlayer: audioPlayer)
                        .opacity(0.7)
                }
                
                // 二维码WebView - 显示在Danmu text下面
                if showQRWebView {
                    QRWebView(url: qrURL.isEmpty ? "https://www.google.com" : qrURL, isVisible: $showQRWebView)
                        .zIndex(10) // 提高z-index确保在最上层
                        .transition(.scale.combined(with: .opacity))
                }
                
                // 调试信息显示
                #if DEBUG
                Text("DEBUG: showQRWebView=\(showQRWebView), qrURL=\(qrURL)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                #endif
                
                // 钱包组件 - 在danmu下面
                WalletView(walletService: walletService)
                    .padding(.top, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading) // 确保整体左对齐
            .padding(.top, 40) // 增加顶部间距
            .padding(.leading, 70) // 增加左边距，让UI更靠左
            .padding(.trailing, 40) // 减少右边距
            
            // 错误信息显示 - 移到左边
            if let error = apiService.error {
                VStack {
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
                    .frame(maxWidth: 300)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 70)
            }
        }
        .onAppear {
            print("NoNoMiProd 应用启动，开始轮询API...")
            apiService.startPolling()
        }
        .onChange(of: apiService.currentStatus) { status in
            // 当有新数据时处理不同action
            if let status = status {
                print("检测到新数据...")
                print("新状态详情: timestamp=\(status.timestamp), voice=\(status.voice ?? ""), action=\(status.action ?? "")")
                
                // 检查是否为pending action
                if status.action == "pending" {
                    print("检测到pending action，播放pending音频...")
                    if !(status.voice ?? "").isEmpty {
                        print("播放pending音频: \(status.voice ?? "")")
                        audioPlayer.autoPlayAudio(from: status.voice ?? "")
                    } else {
                        print("警告: pending action的voice URL为空")
                    }
                }
                // 检查是否为render action（正常完整渲染）
                else if status.action == "render" {
                    print("检测到render action，执行完整渲染...")
                    // 播放语音
                    if !(status.voice ?? "").isEmpty {
                        print("播放render音频: \(status.voice ?? "")")
                        audioPlayer.autoPlayAudio(from: status.voice ?? "")
                    } else {
                        print("警告: render action的voice URL为空")
                    }
                    // Danmu和HTML Widget会自动重新渲染，因为它们绑定到status数据
                    print("Danmu和HTML Widget已重新渲染")
                }
                // 检查是否为二维码action
                else if status.action == "qr", let qrValue = status.value {
                    print("检测到二维码action，显示WebView...")
                    qrURL = qrValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showQRWebView = true
                    }
                }
                // 检查是否为加密货币转账action
                else if status.action == "inj" {
                    print("检测到Injective转账action，播放voice并显示QRCode...")
                    print("🔍 DEBUG - status.value: \(status.value ?? "nil")")
                    
                    // 播放语音
                    if !(status.voice ?? "").isEmpty {
                        print("播放inj音频: \(status.voice ?? "")")
                        audioPlayer.autoPlayAudio(from: status.voice ?? "")
                    } else {
                        print("警告: inj action的voice URL为空")
                    }
                    
                    // 如果有value，显示QRCode WebView
                    if let qrValue = status.value, !qrValue.isEmpty {
                        print("✅ 显示inj的QRCode: \(qrValue)")
                        qrURL = qrValue
                        showQRWebView = true  // 移除动画，直接设置
                        print("🔍 DEBUG - showQRWebView设置为: \(showQRWebView), qrURL设置为: \(qrURL)")
                    } else {
                        print("⚠️ status.value为空或nil，无法显示QRCode")
                        // 临时：即使value为空，也显示一个测试URL来验证QRWebView是否工作
                        print("🧪 TEMP DEBUG - 强制显示测试QRCode")
                        qrURL = "https://www.google.com"
                        showQRWebView = true
                    }
                    
                    // 显示转账界面
                    transferChain = .injective
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTransferView = true
                    }
                }

                // 其他action或无action时，也播放语音（兼容性处理）
                else {
                    print("检测到其他action或无action，播放音频...")
                    print("🔍 DEBUG - 当前action: \(status.action ?? "nil")，不应隐藏inj相关UI")
                    
                    if !(status.voice ?? "").isEmpty {
                        print("开始播放音频: \(status.voice ?? "")")
                        audioPlayer.autoPlayAudio(from: status.voice ?? "")
                    } else {
                        print("警告: voice URL为空，跳过音频播放")
                    }
                    
                    // 只有在非inj和非qr action时才隐藏WebView
                    if status.action != "inj" && status.action != "qr" {
                        print("🔍 DEBUG - 隐藏QRWebView，因为action不是inj或qr")
                        if showQRWebView {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showQRWebView = false
                            }
                        }
                    } else {
                        print("🔍 DEBUG - 保持QRWebView显示，因为action是\(status.action ?? "nil")")
                    }
                    
                    // 只有在非inj action时才隐藏转账视图
                    if status.action != "inj" {
                        print("🔍 DEBUG - 隐藏TransferView，因为action不是inj")
                        if showTransferView {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTransferView = false
                            }
                        }
                    } else {
                        print("🔍 DEBUG - 保持TransferView显示，因为action是inj")
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
        .animation(.easeInOut(duration: 0.3), value: showTransferView)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
