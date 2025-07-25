//
//  ContentView.swift
//  NoNoMi
//
//  Created by Henry on 24/7/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    
    var body: some View {
        ZStack {
            // Reality视图（完全透明，不添加任何3D内容）
            RealityView { content in
                // 不添加任何3D内容，保持完全透明
            } update: { content in
                // 更新逻辑
            }
            // UI控制层
            VStack {
                HStack {
                    // 左上角控制面板
                    controlPanel
                    
                    Spacer()
                    
                    // 右上角截图预览
                    screenshotPreview
                }
                
                Spacer()
                
                // 底部结果显示
                HStack {
                    Spacer()
                    resultView
                }
            }
            .padding()
        }
    }
    
    // 控制面板（左上角）
    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NoNoMi AI")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                captureAndAnalyze()
            }) {
                HStack {
                    Image(systemName: apiService.isLoading ? "circle.dotted" : "camera.fill")
                        .foregroundColor(.white)
                    Text(apiService.isLoading ? "分析中..." : "拍照分析")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.8))
                )
            }
            .disabled(apiService.isLoading)
            
            if apiService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.6))
        )
        .frame(width: 160)
        .onTapGesture {
            // 备用手势：点击控制面板触发
            if !apiService.isLoading {
                captureAndAnalyze()
            }
        }
    }
    
    // 截图预览（右上角）
    private var screenshotPreview: some View {
        Group {
            if let screenshot = apiService.latestScreenshot {
                VStack(alignment: .trailing, spacing: 8) {
                    Text("最新截图")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Image(uiImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 90)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button("清除") {
                        apiService.clearAll()
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // 结果显示区域（底部右侧）
    private var resultView: some View {
        Group {
            if !apiService.responseText.isEmpty {
                VStack(alignment: .trailing, spacing: 8) {
                    Text("AI 视角:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(apiService.responseText)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(6)
                    
                    Button("清除回复") {
                        apiService.responseText = ""
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.7))
                )
                .frame(maxWidth: 280)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // 截图并分析功能
    private func captureAndAnalyze() {
        // 截取当前视图
        if let screenshot = apiService.captureCurrentView() {
            // 调用API分析
            apiService.sendImageToAgent(image: screenshot)
        } else {
            apiService.responseText = "截图失败"
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
