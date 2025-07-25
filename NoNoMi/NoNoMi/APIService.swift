//
//  APIService.swift
//  NoNoMi
//
//  Created by Henry on 24/7/2025.
//

import SwiftUI
import UIKit
import Foundation
import RealityKit
import WebKit

// HTML Widget数据模型
struct HtmlWidget: Identifiable, Codable {
    let id = UUID()
    let x: Int
    let y: Int
    let height: Int
    let width: Int
    let html: String
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let agentApiURL = "https://adventurex-2025.vercel.app/agent"
    private let renderApiURL = "https://adventurex-2025.vercel.app/render"
    private let apiKey = "qaq"
    
    @Published var responseText: String = ""
    @Published var isLoading: Bool = false
    @Published var latestScreenshot: UIImage? = nil
    @Published var htmlWidgets: [HtmlWidget] = []
    @Published var isRenderingWidgets: Bool = false
    
    // Configure URLSession with proper settings to prevent socket errors
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        // Prevent socket reuse issues
        config.httpMaximumConnectionsPerHost = 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        // Add proper headers to prevent connection issues
        config.httpAdditionalHeaders = [
            "Connection": "keep-alive",
            "User-Agent": "NoNoMi-iOS/1.0"
        ]
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // 将UIImage转为base64字符串
    func imageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        return imageData.base64EncodedString()
    }
    
    // 截取当前窗口/视图层次
    func captureCurrentView() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        return renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
    
    // 调用/agent API
    func sendImageToAgent(image: UIImage, prompt: String = "you are a god and this is your view, reply in Chinese about what you thought, reply limit in 20-50 words in Chinese") {
        // 存储最新截图
        latestScreenshot = image
        
        guard let base64String = imageToBase64(image) else {
            responseText = "图片转换失败"
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: agentApiURL) else {
            responseText = "API URL无效"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let imageUrlString = "data:image/jpeg;base64,\(base64String)"
        
        let content: [[String: Any]] = [
            ["type": "text", "text": prompt],
            ["type": "image_url", "image_url": ["url": imageUrlString]]
        ]
        
        let body: [String: Any] = [
            "messages": [["role": "user", "content": content]]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            responseText = "请求数据序列化失败: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self?.responseText = "网络错误: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        self?.responseText = "服务器错误: \(httpResponse.statusCode)"
                        return
                    }
                }
                
                guard let data = data else {
                    self?.responseText = "无数据返回"
                    return
                }
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let result = jsonResponse["result"] as? String {
                        self?.responseText = result
                    } else {
                        self?.responseText = "解析响应失败"
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    self?.responseText = "JSON解析错误: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // 调用/render API生成HTML widgets
    func generateWidgets(image: UIImage, text: String = "", customPrompt: String? = nil) {
        guard let base64String = imageToBase64(image) else {
            responseText = "图片转换失败"
            return
        }
        
        isRenderingWidgets = true
        htmlWidgets = []
        
        guard let url = URL(string: renderApiURL) else {
            responseText = "Render API URL无效"
            isRenderingWidgets = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0 // Longer timeout for widget generation
        request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let imageUrlString = "data:image/jpeg;base64,\(base64String)"
        
        // 构建提示词，包含图像和文本信息
        var promptText = customPrompt ?? """
        Based on the provided image and text context, create helpful HTML widgets for a VisionPro AR interface. 
        Generate interactive widgets that complement what's shown in the image.
        
        Image context: What you see in the image
        Text context: \(text.isEmpty ? "No text provided" : text)
        
        Create useful widgets like:
        - Information panels
        - Interactive buttons
        - Progress indicators  
        - Data displays
        - Context-relevant tools
        
        Each widget should be positioned appropriately and use modern HTML/CSS.
        Make widgets visually appealing with proper styling, colors, and responsive design.
        """
        
        let content: [[String: Any]] = [
            ["type": "text", "text": promptText],
            ["type": "image_url", "image_url": ["url": imageUrlString]]
        ]
        
        let body: [String: Any] = [
            "messages": [["role": "user", "content": content]]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            responseText = "请求数据序列化失败: \(error.localizedDescription)"
            isRenderingWidgets = false
            return
        }
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isRenderingWidgets = false
                
                if let error = error {
                    print("Widget generation error: \(error.localizedDescription)")
                    self?.responseText = "网络错误: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Widget response status code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        self?.responseText = "服务器错误: \(httpResponse.statusCode)"
                        return
                    }
                }
                
                guard let data = data else {
                    self?.responseText = "无数据返回"
                    return
                }
                
                do {
                    // 解析返回的HTML widgets数组
                    let decoder = JSONDecoder()
                    let widgetData = try decoder.decode([HtmlWidget].self, from: data)
                    self?.htmlWidgets = widgetData
                    self?.responseText = "成功生成 \(widgetData.count) 个widgets"
                } catch {
                    print("Widget解析错误: \(error)")
                    // Try to parse as error response
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorJson["error"] as? String {
                        self?.responseText = "服务器错误: \(errorMessage)"
                    } else {
                        self?.responseText = "Widget解析错误: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
    
    // 清除数据
    func clearAll() {
        responseText = ""
        latestScreenshot = nil
        htmlWidgets = []
    }
    
    // 清除widgets
    func clearWidgets() {
        htmlWidgets = []
    }
} 