//
//  StatusIndicatorView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI

struct StatusIndicatorView: View {
    @ObservedObject var apiService: APIService
    
    var body: some View {
        HStack(spacing: 8) {
            // 连接状态指示器
            HStack(spacing: 4) {
                Circle()
                    .fill(apiService.error == nil ? Color.green : Color.red)
                    .frame(width: 18, height: 18)
                
                Text(apiService.error == nil ? "已连接" : "连接错误")
                    .font(.system(size: 46, weight: .medium)) // 增加字体大小 (38 * 1.2)
                    .foregroundColor(apiService.error == nil ? .green : .red)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.3), value: apiService.error)
            }
            
            // 加载指示器
            if apiService.isLoading {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(1.8)
                        .frame(width: 36, height: 36)
                    
                    Text("更新中...")
                        .font(.system(size: 46, weight: .medium)) // 增加字体大小 (38 * 1.2)
                        .foregroundColor(.blue)
                }
            }
            
            // 移除时间戳显示
        }
        .padding(.horizontal, 19) // 增加水平内边距 (16 * 1.2)
        .padding(.vertical, 12) // 增加垂直内边距 (10 * 1.2)
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
    }
}

#Preview {
    StatusIndicatorView(apiService: APIService())
} 