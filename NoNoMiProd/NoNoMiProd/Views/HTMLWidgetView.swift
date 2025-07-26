//
//  HTMLWidgetView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI
import WebKit

struct HTMLWidgetView: UIViewRepresentable {
    let html: String
    let width: Int
    let height: Int
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // 配置 WebView
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 如果 HTML 包含 React 组件或特殊内容，直接加载
        if html.contains("react") || html.contains("React") || html.contains("magicui") {
            // 加载本地 React 页面
            if let url = Bundle.main.url(forResource: "widget", withExtension: "html") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                // 如果本地文件不存在，加载在线版本
                if let url = URL(string: "https://yourdomain.com/widget.html") {
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
            }
        } else {
            // 普通 HTML 内容
            let htmlContent = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { 
                        margin: 0; 
                        padding: 0; 
                        background: transparent; 
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    }
                    .container { 
                        width: 100%; 
                        height: 100vh; 
                        display: flex; 
                        align-items: center; 
                        justify-content: center; 
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    \(html)
                </div>
            </body>
            </html>
            """
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
}

// 预览
struct HTMLWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLWidgetView(
            html: "<div style='background: linear-gradient(135deg, #69bff9, #b96af3, #e9685e, #f2ac3e); border-radius: 12px; padding: 20px; color: white;'>Hello World!</div>",
            width: 300,
            height: 200
        )
        .frame(width: 300, height: 200)
        .background(Color.black)
    }
} 