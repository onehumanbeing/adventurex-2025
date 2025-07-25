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
                    .font(.system(size: 33, weight: .medium))
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
                        .font(.system(size: 33, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            // 移除时间戳显示
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    StatusIndicatorView(apiService: APIService())
} 