# NoNoMiProd - VisionOS 实时数据展示应用

## 项目概述

NoNoMiProd 是一个专为 Apple Vision Pro 设计的实时数据展示应用，通过多个小视图组件展示从API获取的数据，同时最大化用户的Reality视野体验。

## 主要功能

### 1. 实时数据轮询
- 每3秒自动轮询API：`https://helped-monthly-alpaca.ngrok-free.app/status.json`
- 智能时间戳检测，只处理新数据
- 实时连接状态监控

### 2. 多组件视图布局
- **左上角**：旁白文字显示 (`danmu_text`)
- **右上角**：连接状态和加载指示器
- **右侧**：HTML内容渲染器 (支持自定义宽高)
- **右下角**：音频播放控制器

### 3. 音频播放功能
- 支持在线音频播放
- 播放状态可视化指示
- 一键播放/停止控制

### 4. HTML内容渲染
- 使用WebKit渲染HTML内容
- 支持自定义尺寸
- 透明背景，不遮挡视野

## 技术架构

### 数据模型
- `StatusData`: API返回数据的结构定义

### 服务层
- `APIService`: 处理API轮询和数据获取
- `AudioPlayer`: 音频播放管理

### 视图组件
- `DanmuView`: 旁白文字显示
- `HTMLWidgetView`: HTML内容渲染
- `AudioControlView`: 音频控制界面
- `StatusIndicatorView`: 状态指示器

## API数据格式

```json
{
    "voice": "https://helped-monthly-alpaca.ngrok-free.app/voice/1753466080.mp3",
    "timestamp": 1753466080,
    "html": "<div style='text-align:center;'><h2>关于时尚和购物的对话</h2>...</div>",
    "danmu_text": "对灰绿色裤子的赞美，探讨衣物价格与购物渠道的对话。",
    "height": 600,
    "width": 800
}
```

## 设计理念

### 视野优化
- 所有UI组件使用半透明材质
- 组件位置精心设计，避免遮挡中心视野
- 支持动画过渡，提供流畅的用户体验

### 用户体验
- 实时状态反馈
- 直观的图标和颜色编码
- 响应式布局适配不同场景

## 开发环境

- Xcode 15.0+
- visionOS SDK
- SwiftUI
- RealityKit

## 构建和运行

1. 在Xcode中打开 `NoNoMiProd.xcodeproj`
2. 选择Vision Pro模拟器或设备
3. 构建并运行项目

## 注意事项

- 确保网络连接正常以访问API
- 应用需要网络权限来访问外部API
- HTML内容支持标准HTML标签和CSS样式 