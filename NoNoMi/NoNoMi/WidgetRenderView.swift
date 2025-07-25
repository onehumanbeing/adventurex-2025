//
//  WidgetRenderView.swift
//  NoNoMi
//
//  Created by AI Assistant on 24/7/2025.
//

import SwiftUI
import WebKit

// 单个HTML Widget渲染器
struct HtmlWidgetView: UIViewRepresentable {
    let widget: HtmlWidget
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // 禁用用户交互，避免干扰AR体验
        webView.isUserInteractionEnabled = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 创建完整的HTML页面
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    overflow: hidden;
                }
                * {
                    box-sizing: border-box;
                }
            </style>
        </head>
        <body>
            \(widget.html)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

// Widget容器视图
struct WidgetRenderView: View {
    @ObservedObject var apiService = APIService.shared
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            // 渲染所有HTML widgets
            ForEach(apiService.htmlWidgets) { widget in
                HtmlWidgetView(widget: widget)
                    .frame(
                        width: CGFloat(widget.width),
                        height: CGFloat(widget.height)
                    )
                    .position(
                        x: CGFloat(widget.x) + CGFloat(widget.width) / 2,
                        y: CGFloat(widget.y) + CGFloat(widget.height) / 2
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.1))
                            .blur(radius: 1)
                    )
            }
            
            // Widget控制面板
            if !apiService.htmlWidgets.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        widgetControlPanel
                    }
                }
                .padding()
            }
        }
    }
    
    // Widget控制面板
    private var widgetControlPanel: some View {
        VStack(spacing: 8) {
            Text("Widgets: \(apiService.htmlWidgets.count)")
                .font(.caption2)
                .foregroundColor(.white)
            
            Button("清除Widgets") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    apiService.clearWidgets()
                }
            }
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.7))
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
        )
    }
}

// Widget生成控制面板
struct WidgetGeneratorPanel: View {
    @ObservedObject var apiService = APIService.shared
    @ObservedObject var listeningViewModel: ListeningViewModel
    @Binding var showWidgetGenerator: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Widget Generator")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("×") {
                    showWidgetGenerator = false
                }
                .font(.title2)
                .foregroundColor(.white)
            }
            
            // 显示当前语音识别文本
            if !listeningViewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("语音文本:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        Text(listeningViewModel.transcribedText)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 60)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
            }
            
            Button(action: {
                generateWidgetsFromCurrentState()
            }) {
                HStack {
                    Image(systemName: apiService.isRenderingWidgets ? "circle.dotted" : "wand.and.stars")
                        .foregroundColor(.white)
                    Text(apiService.isRenderingWidgets ? "生成中..." : "生成Widgets")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.8))
                )
            }
            .disabled(apiService.isRenderingWidgets || apiService.latestScreenshot == nil)
            
            if apiService.isRenderingWidgets {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.8))
        )
        .frame(width: 260)
    }
    
    private func generateWidgetsFromCurrentState() {
        guard let screenshot = apiService.latestScreenshot else {
            apiService.responseText = "请先拍照获取截图"
            return
        }
        
        let textContext = listeningViewModel.transcribedText
        apiService.generateWidgets(image: screenshot, text: textContext)
        showWidgetGenerator = false
    }
}

#Preview {
    WidgetRenderView(screenSize: CGSize(width: 800, height: 600))
} 