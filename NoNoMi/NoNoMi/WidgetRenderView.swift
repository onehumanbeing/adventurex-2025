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
        
        // 允许用户交互，但适配AR环境
        webView.isUserInteractionEnabled = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 创建完整的HTML页面，背景透明
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
                    background: rgba(0, 0, 0, 0.1); /* 极淡的半透明背景 */
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    overflow: hidden;
                    backdrop-filter: blur(10px); /* 毛玻璃效果 */
                    border-radius: 12px;
                }
                * {
                    box-sizing: border-box;
                }
                /* 增强可读性的默认样式 */
                h1, h2, h3, h4, h5, h6 {
                    color: #ffffff;
                    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
                }
                p, span, div {
                    color: #f0f0f0;
                    text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.7);
                }
                button {
                    backdrop-filter: blur(5px);
                    border: 1px solid rgba(255, 255, 255, 0.3);
                    border-radius: 8px;
                    color: white;
                    text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.8);
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
                            .fill(Color.black.opacity(0.05)) // 极淡的背景
                            .blur(radius: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
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
    
    // Widget控制面板 - 透明背景
    private var widgetControlPanel: some View {
        VStack(spacing: 8) {
            Text("Widgets: \(apiService.htmlWidgets.count)")
                .font(.caption2)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
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
                    .fill(Color.red.opacity(0.6)) // 降低不透明度
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2)) // 大幅降低不透明度
                .blur(radius: 8)
        )
    }
}

// Widget生成控制面板 - 透明背景
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
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                
                Spacer()
                
                Button("×") {
                    showWidgetGenerator = false
                }
                .font(.title2)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            }
            
            // 显示当前语音识别文本
            if !listeningViewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("语音文本:")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    ScrollView {
                        Text(listeningViewModel.transcribedText)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                    }
                    .frame(height: 60)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.2)) // 降低不透明度
                            .blur(radius: 3)
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
                        .fill(Color.green.opacity(0.7)) // 降低不透明度
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
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
                .fill(Color.black.opacity(0.4)) // 降低不透明度
                .blur(radius: 15) // 增强模糊效果
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