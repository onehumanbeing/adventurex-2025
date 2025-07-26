# 二维码检测与WebView功能

## 功能概述

当检测到二维码时，系统会自动：
1. 更新 `./cache/status.json` 文件，添加 `action: "qr"` 和 `value: "链接"` 字段
2. 更新 `timestamp` 字段
3. 在 NoNoMiProd 应用中显示 WebView 来展示二维码链接内容
4. 重新播放语音和渲染弹幕文本

## 实现细节

### 1. 后端检测 (local/detector.py)

- **新增函数**: `update_status_json(qr_content: str)`
  - 读取现有的 `status.json` 文件
  - 添加 `action: "qr"` 和 `value: qr_content` 字段
  - 更新 `timestamp` 为当前时间戳
  - 保存文件，保持其他字段不变

- **集成**: 在 `detect_qr_codes()` 函数中调用 `update_status_json()`
  - 当检测到二维码时自动更新 status.json
  - 支持多种检测方式（原图、灰度图、放大图）

### 2. 数据模型更新 (NoNoMiProd/Models/StatusData.swift)

```swift
struct StatusData: Codable, Equatable {
    let voice: String
    let timestamp: Int
    let html: String
    let danmu_text: String
    let height: Int
    let width: Int
    let action: String?    // 新增：动作类型
    let value: String?     // 新增：动作值
}
```

### 3. WebView 组件 (NoNoMiProd/Views/QRWebView.swift)

- **QRWebView**: 主要的二维码显示组件
  - 包含标题栏和关闭按钮
  - 使用 `URLWebView` 显示网页内容
  - 支持动画过渡效果

- **URLWebView**: 底层 WebView 实现
  - 基于 WKWebView 的 UIViewRepresentable
  - 支持导航代理和错误处理
  - 自动加载指定 URL

### 4. 主界面集成 (NoNoMiProd/ContentView.swift)

- **状态管理**:
  - `@State private var showQRWebView = false`
  - `@State private var qrURL = ""`

- **逻辑处理**:
  ```swift
  .onChange(of: apiService.currentStatus) { newStatus in
      if let status = newStatus {
          // 自动播放音频
          audioPlayer.autoPlayAudio(from: status.voice)
          
          // 检查二维码action
          if status.action == "qr", let qrValue = status.value {
              qrURL = qrValue
              withAnimation(.easeInOut(duration: 0.3)) {
                  showQRWebView = true
              }
          } else {
              // 隐藏WebView
              if showQRWebView {
                  withAnimation(.easeInOut(duration: 0.3)) {
                      showQRWebView = false
                  }
              }
          }
      }
  }
  ```

## 工作流程

1. **监控**: `detector.py` 持续监控截图目录
2. **检测**: 当有新图片时，自动检测二维码
3. **更新**: 检测到二维码后，更新 `status.json`
4. **同步**: NoNoMiProd 应用轮询 API，获取更新
5. **显示**: 当 `action == "qr"` 时，显示 WebView
6. **播放**: 重新播放语音和渲染弹幕

## 测试

运行测试脚本验证功能：

```bash
cd local
python3 test_qr.py
```

## 文件结构

```
adx/
├── local/
│   ├── detector.py          # 二维码检测和status.json更新
│   ├── test_qr.py          # 测试脚本
│   └── cache/
│       └── status.json     # 状态文件
└── NoNoMiProd/
    └── NoNoMiProd/
        ├── Models/
        │   └── StatusData.swift    # 数据模型
        ├── Views/
        │   └── QRWebView.swift     # WebView组件
        └── ContentView.swift       # 主界面
```

## 注意事项

1. **命名冲突**: 避免与现有的 `WebView` 组件冲突，使用 `URLWebView` 和 `QRWebView`
2. **错误处理**: WebView 包含完整的错误处理和日志记录
3. **动画效果**: 使用 SwiftUI 动画提供流畅的用户体验
4. **状态管理**: 正确处理 WebView 的显示/隐藏状态 