//
//  APIService.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import Foundation
import Combine

class APIService: ObservableObject {
    @Published var currentStatus: StatusData?
    @Published var isLoading = false
    @Published var error: String?
    
    private var timer: Timer?
    private let url = "https://helped-monthly-alpaca.ngrok-free.app/status.json"
    private var lastTimestamp: Int = 0
    
    func startPolling() {
        print("APIService: 开始轮询API - \(url)")
        // 立即获取一次数据
        fetchStatus()
        
        // 每3秒轮询一次
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchStatus()
        }
    }
    
    func stopPolling() {
        print("APIService: 停止轮询API")
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchStatus() {
        isLoading = true
        error = nil
        
        guard let url = URL(string: self.url) else {
            error = "Invalid URL"
            isLoading = false
            print("APIService: URL无效 - \(self.url)")
            return
        }
        
        print("APIService: 正在获取数据...")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("APIService: 网络错误 - \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    print("APIService: 未接收到数据")
                    return
                }
                
                // 打印原始数据用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("APIService: 接收到数据 - \(jsonString)")
                }
                
                do {
                    let status = try JSONDecoder().decode(StatusData.self, from: data)
                    print("APIService: 解析成功 - timestamp: \(status.timestamp), lastTimestamp: \(self?.lastTimestamp ?? 0)")
                    
                    // 检查时间戳，只处理新的数据
                    if status.timestamp > self?.lastTimestamp ?? 0 {
                        print("APIService: 时间戳更新，更新状态数据")
                        print("APIService: 新数据详情 - voice: \(status.voice), danmu_text: \(status.danmu_text)")
                        print("🔍 APIService DEBUG - action: \(status.action ?? "nil"), value: \(status.value ?? "nil")")
                        print("📊 APIService DEBUG - 完整数据: voice=\(status.voice), timestamp=\(status.timestamp), html=\(status.html.prefix(100))..., width=\(status.width), height=\(status.height)")
                        self?.lastTimestamp = status.timestamp
                        self?.currentStatus = status
                        print("APIService: 状态数据已更新")
                    } else {
                        print("APIService: 时间戳未更新，忽略数据 (当前: \(status.timestamp), 上次: \(self?.lastTimestamp ?? 0))")
                    }
                } catch {
                    self?.error = "Failed to decode data: \(error.localizedDescription)"
                    print("APIService: 数据解析失败 - \(error.localizedDescription)")
                }
            }
        }.resume()
    }
} 