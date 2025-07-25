import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var listeningViewModel = ListeningViewModel()
    @State private var showWidgetGenerator = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Reality视图（完全透明背景）
                RealityView { content in
                    // 完全透明，不添加任何3D内容
                } update: { content in
                    // 更新逻辑
                }
                .background(Color.clear) // 确保背景透明
                
                // HTML Widgets渲染层
                WidgetRenderView(screenSize: geometry.size)
                
                // UI控制层（浮动透明UI）
                VStack {
                    HStack {
                        // 左上角控制面板
                        controlPanel
                        Spacer()
                        // 右上角截图预览
                        screenshotPreview
                    }
                    Spacer()
                    // 底部区域
                    HStack {
                        // 左下角固定ListeningView
                        ListeningPanel(viewModel: listeningViewModel)
                        Spacer()
                        resultView
                    }
                }
                .padding()
                
                // Widget生成面板（可显示/隐藏）
                if showWidgetGenerator {
                    VStack {
                        HStack {
                            Spacer()
                            WidgetGeneratorPanel(
                                apiService: apiService,
                                listeningViewModel: listeningViewModel,
                                showWidgetGenerator: $showWidgetGenerator
                            )
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.black.opacity(0.1)) // 非常淡的背景
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .background(Color.clear) // 主视图背景透明
        .preferredColorScheme(.dark) // 深色模式适合AR
    }
    
    // 控制面板（左上角）- 透明背景
    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NoNoMi AI")
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1) // 添加阴影增强可读性
            
            // 拍照分析按钮
            Button(action: {
                captureAndAnalyze()
            }) {
                HStack {
                    Image(systemName: apiService.isLoading ? "circle.dotted" : "camera.fill")
                        .foregroundColor(.white)
                    Text(apiService.isLoading ? "分析中..." : "拍照分析")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.7)) // 降低不透明度
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                )
            }
            .disabled(apiService.isLoading)
            
            // Widget生成按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showWidgetGenerator.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.white)
                    Text("生成Widgets")
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
            .disabled(apiService.latestScreenshot == nil)
            
            if apiService.isLoading || apiService.isRenderingWidgets {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3)) // 大幅降低不透明度
                .blur(radius: 10) // 添加模糊效果
        )
        .frame(width: 160)
        .onTapGesture {
            // 备用手势：点击控制面板触发
            if !apiService.isLoading {
                captureAndAnalyze()
            }
        }
    }
    
    // 截图预览（右上角）- 透明背景
    private var screenshotPreview: some View {
        Group {
            if let screenshot = apiService.latestScreenshot {
                VStack(alignment: .trailing, spacing: 8) {
                    Text("用户视野")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    Image(uiImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 90)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    Button("清除") {
                        apiService.clearAll()
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3)) // 降低不透明度
                        .blur(radius: 10)
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // 结果显示区域（底部右侧）- 透明背景
    private var resultView: some View {
        Group {
            if !apiService.responseText.isEmpty {
                VStack(alignment: .trailing, spacing: 8) {
                    Text("AI 反馈:")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    Text(apiService.responseText)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(6)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    Button("清除回复") {
                        apiService.responseText = ""
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.4)) // 降低不透明度
                        .blur(radius: 8)
                )
                .frame(maxWidth: 280)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // 更新的截图并分析功能 - 使用新的API方法
    private func captureAndAnalyze() {
        // 使用新的方法获取用户视野
        apiService.captureAndAnalyze()
        
        // 如果有截图，调用AI分析
        if let screenshot = apiService.latestScreenshot {
            apiService.sendImageToAgent(image: screenshot)
        }
    }

}

// 左下角固定ListeningView面板 - 透明背景
struct ListeningPanel: View {
    @ObservedObject var viewModel: ListeningViewModel
    @State private var isListening = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("语音助手")
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            
            Button(action: {
                print("[ListeningPanel] Button tapped. isListening=\(isListening)")
                if isListening {
                    print("[ListeningPanel] Stop listening")
                    viewModel.stopListening()
                } else {
                    print("[ListeningPanel] Start listening")
                    viewModel.startListening()
                }
                isListening.toggle()
            }) {
                HStack {
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .foregroundColor(.white)
                    Text(isListening ? "正在聆听..." : "开始聆听")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.purple.opacity(0.7)) // 降低不透明度
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                )
            }
            
            if isListening {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            if !viewModel.transcribedText.isEmpty {
                ScrollView {
                    Text(viewModel.transcribedText)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.2)) // 大幅降低不透明度
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
                .frame(height: 60)
            }
            
            // 清除文本按钮
            if !viewModel.transcribedText.isEmpty {
                Button("清除文本") {
                    viewModel.transcribedText = ""
                }
                .font(.caption2)
                .foregroundColor(.orange)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3)) // 大幅降低不透明度
                .blur(radius: 10)
        )
        .frame(width: 180)
        .padding(.bottom, 8)
        .padding(.leading, 8)
        .onReceive(viewModel.$isListening) { listening in
            isListening = listening
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}


