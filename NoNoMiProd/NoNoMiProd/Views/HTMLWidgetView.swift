//
//  HTMLWidgetView.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI
import WebKit

struct HTMLWidgetView: View {
    let html: String
    let width: Int
    let height: Int
    
    // 将API返回的像素尺寸转换为SwiftUI的尺寸
    private var widgetSize: CGSize {
        // 调整缩放比例，让HTML Widget在右侧显示时更合适
        let scale: CGFloat = 1.08 // 调整为1.08 (0.9 * 1.2)，让HTML Widget更大更清晰
        return CGSize(
            width: CGFloat(width) * scale,
            height: CGFloat(height) * scale
        )
    }
    
    var body: some View {
        WebView(html: html)
            .frame(width: widgetSize.width, height: widgetSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12)) // 增加圆角
            .background(
                RoundedRectangle(cornerRadius: 16) // 增加背景圆角
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
    }
}

struct WebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = false
        
        // 注入CSS来调整内容缩放
        let scriptSource = """
        var style = document.createElement('style');
        style.innerHTML = 'body { transform: scale(2.5); transform-origin: top left; }'; // 调整缩放比例
        document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    HTMLWidgetView(
        html: "<div style='text-align:center;'><h2>关于时尚和购物的对话</h2><p>在这组对话中，体现了对衣物款式的欣赏与购买意向：</p><ul><li>对灰绿色裤子的赞美，表示出不俗的品味。</li><li>令人好奇的购物渠道，展现了对服装风格的渴望。</li><li>衣物的款式与价格也是关注的重点，典型的购物对话情境。</li></ul></div>",
        width: 800,
        height: 600
    )
} 