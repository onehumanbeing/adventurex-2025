# /agent API 说明

## 路径
POST /agent

## 认证
- 需要在请求头中添加 `X-API-KEY`，值为后端环境变量 `AGENT_API_KEY`。

## 请求体
- JSON 格式，包含字段：
  - `messages`: 一个消息数组。每个消息可包含文本和图片。

### 支持图片上传
- 图片以 base64 编码后，作为 `image_url` 类型嵌入到 `content` 数组中。
- 示例：

```json
{
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "请分析这张图片"},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,BASE64_IMAGE_STRING"}}
      ]
    }
  ]
}
```


## 响应
- 成功：返回 agent 处理后的 JSON。
- 失败：返回 401（未授权）或 400（缺少 messages 字段）。

---

# Swift 调用示例（含图片上传）

```swift
import Foundation
import UIKit

func sendImageToAgent(image: UIImage, apiKey: String) {
    let url = URL(string: "http://YOUR_BACKEND_HOST/agent")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // 将 UIImage 转为 JPEG 并 base64 编码
    guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
    let base64String = imageData.base64EncodedString()
    let imageUrlString = "data:image/jpeg;base64,\(base64String)"

    let content: [[String: Any]] = [
        ["type": "text", "text": "请分析这张图片"],
        ["type": "image_url", "image_url": ["url": imageUrlString]]
    ]
    let body: [String: Any] = [
        "messages": [["role": "user", "content": content]]
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            print(String(data: data, encoding: .utf8) ?? "")
        } else if let error = error {
            print("Error: \(error)")
        }
    }
    task.resume()
}
``` 