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

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let apiURL = "https://adventurex-2025.vercel.app/agent"
    private let apiKey = "qaq"
    
    @Published var responseText: String = ""
    @Published var isLoading: Bool = false
    @Published var latestScreenshot: UIImage? = nil
    
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
        
        guard let url = URL(string: apiURL) else {
            responseText = "API URL无效"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.responseText = "网络错误: \(error.localizedDescription)"
                    return
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
                    self?.responseText = "JSON解析错误: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // 清除数据
    func clearAll() {
        responseText = ""
        latestScreenshot = nil
    }
} 