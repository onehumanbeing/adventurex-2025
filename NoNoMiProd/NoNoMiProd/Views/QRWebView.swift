//
//  QRWebView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI
import WebKit

struct QRWebView: View {
    let url: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("二维码链接")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // WebView内容 - 添加圆角
            URLWebView(url: url)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12)) // 为WebView内容添加圆角
        }
        .frame(width: 480, height: 540) // 增加尺寸 (400 * 1.2, 450 * 1.2)
        .background(
            RoundedRectangle(cornerRadius: 20) // 增加整体圆角半径
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20)) // 确保整个视图都有圆角
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
}

struct URLWebView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // 设置WebView的圆角
        webView.layer.cornerRadius = 12
        webView.layer.masksToBounds = true
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: URLWebView
        
        init(_ parent: URLWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("开始加载网页: \(parent.url)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("网页加载完成: \(parent.url)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("网页加载失败: \(error.localizedDescription)")
        }
    }
} 