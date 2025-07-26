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
        // 添加调试信息
        let _ = print("🎯 QRWebView 正在渲染 - URL: \(url), isVisible: \(isVisible)")
        VStack(spacing: 0) {
            // 调试信息栏 - 临时添加
            HStack {
                Text("🎯 QRWebView 已显示!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                Spacer()
            }
            .padding(.horizontal)
            
            // 标题栏
            HStack {
                Text("二维码链接")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("URL: \(url.prefix(30))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
            ZStack {
                URLWebView(url: url)
                    .background(Color(.systemBackground))
                
                // 临时添加一个文本fallback
                VStack {
                    Text("正在加载...")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("在浏览器中打开") {
                        if let url = URL(string: url) {
                            #if os(iOS)
                            UIApplication.shared.open(url)
                            #endif
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16)) // 为WebView内容添加圆角
        }
        .frame(width: 480, height: 540) // 增加尺寸 (400 * 1.2, 450 * 1.2)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.6), Color.gray.opacity(0.3), Color.black.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24)) // 确保整个视图都有圆角
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
}

struct URLWebView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        print("🌐 URLWebView makeUIView 被调用 - URL: \(url)")
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // 设置WebView的圆角
        webView.layer.cornerRadius = 16
        webView.layer.masksToBounds = true
        
        // 设置背景色以便调试
        webView.backgroundColor = .systemBlue
        webView.scrollView.backgroundColor = .systemBlue
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        print("🔄 URLWebView updateUIView 被调用 - URL: \(url)")
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            print("📤 开始加载URL请求: \(url)")
            uiView.load(request)
        } else {
            print("❌ 无效的URL: \(url)")
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