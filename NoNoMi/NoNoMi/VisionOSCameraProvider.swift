import SwiftUI
import ARKit
import RealityKit
import Combine

#if !os(iOS)
// visionOS专用真实摄像头提供者
// 基于 https://developer.apple.com/documentation/visionos/accessing-the-main-camera
@available(visionOS 2.0, *)
class VisionOSCameraProvider: ObservableObject {
    @Published var latestCameraFrame: UIImage?
    @Published var isActive: Bool = false
    @Published var errorMessage: String?
    
    private var arkitSession: ARKitSession?
    private var cameraFrameProvider: CameraFrameProvider?
    private var frameProcessingTask: Task<Void, Never>?
    
    init() {
        print("[VisionOSCamera] 初始化visionOS摄像头提供者")
    }
    
    func startCameraCapture() async {
        print("[VisionOSCamera] 启动visionOS摄像头...")
        
        do {
            guard CameraFrameProvider.isSupported else {
                await MainActor.run {
                    self.errorMessage = "CameraFrameProvider不支持 - 需要Enterprise权限"
                }
                return
            }
            
            let session = ARKitSession()
            let provider = CameraFrameProvider()
            
            // 请求摄像头权限
            let authorizationResult = await session.queryAuthorization(for: [.cameraAccess])
            
            for (authType, status) in authorizationResult {
                print("[VisionOSCamera] 权限 \(authType): \(status)")
                if status != .allowed {
                    await MainActor.run {
                        self.errorMessage = "摄像头权限被拒绝: \(authType)"
                    }
                    return
                }
            }
            
            // 启动会话
            try await session.run([provider])
            
            self.arkitSession = session
            self.cameraFrameProvider = provider
            
            await MainActor.run {
                self.isActive = true
                self.errorMessage = nil
            }
            
            print("[VisionOSCamera] ✅ 摄像头会话启动成功")
            
            // 开始处理帧数据
            await processCameraFrames(provider: provider)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "启动失败: \(error.localizedDescription)"
                self.isActive = false
            }
        }
    }
    
    func stopCameraCapture() {
        frameProcessingTask?.cancel()
        frameProcessingTask = nil
        arkitSession?.stop()
        arkitSession = nil
        cameraFrameProvider = nil
        
        DispatchQueue.main.async {
            self.isActive = false
            self.latestCameraFrame = nil
        }
    }
    
    // 处理摄像头帧流
    private func processCameraFrames(provider: CameraFrameProvider) async {
        frameProcessingTask = Task {
            do {
                // 获取所有支持的摄像头格式
                let allFormats = CameraVideoFormat.supportedVideoFormats(for: .main, cameraPositions: [])
                
                guard let format = allFormats.first else {
                    print("[VisionOSCamera] 没有可用的摄像头格式")
                    return
                }
                
                print("[VisionOSCamera] 使用格式: \(format)")
                
                // 获取摄像头帧流
                guard let frameUpdates = provider.cameraFrameUpdates(for: format) else {
                    print("[VisionOSCamera] 无法获取摄像头帧流")
                    return
                }
                
                print("[VisionOSCamera] 开始接收摄像头帧...")
                
                for await cameraFrame in frameUpdates {
                    guard !Task.isCancelled else { break }
                    
                    if let image = await extractImageFromCameraFrame(cameraFrame) {
                        await MainActor.run {
                            self.latestCameraFrame = image
                        }
                    }
                }
                
            } catch {
                print("[VisionOSCamera] 处理帧错误: \(error)")
            }
        }
    }
    
    // 从CameraFrame提取图像数据
    private func extractImageFromCameraFrame(_ frame: CameraFrame) async -> UIImage? {
        // 方法1: 尝试直接从CameraFrame获取sample
        // 首先检查CameraFrame有什么可用的API
        
        // 使用Mirror检查frame的结构
        let mirror = Mirror(reflecting: frame)
        for child in mirror.children {
            if let label = child.label {
                print("[VisionOSCamera] CameraFrame.\(label): \(type(of: child.value))")
            }
        }
        
        // 根据Apple文档，CameraFrame应该有sample方法
        // 尝试不同的调用方式来获取像素数据
        
        // 这里需要找到正确的API调用方式
        // 暂时返回一个占位图像，表明我们确实接收到了CameraFrame
        return createFrameReceivedIndicator()
    }
    
    // 创建接收到帧的指示图像
    private func createFrameReceivedIndicator() -> UIImage {
        let size = CGSize(width: 1920, height: 1440)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 绿色背景表示正在接收真实帧
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let text = "visionOS CameraFrame\nReceived Successfully\n\(Date().timeIntervalSince1970)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: textRect)
        }
    }
    
    deinit {
        stopCameraCapture()
    }
}

// 简化的兼容层，只为visionOS
@available(visionOS 1.0, *)
class VisionOSCameraProviderCompat: ObservableObject {
    @Published var latestCameraFrame: UIImage?
    @Published var isActive: Bool = false
    @Published var errorMessage: String?
    
    private var realProvider: VisionOSCameraProvider?
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        print("[VisionOSCameraCompat] 初始化")
    }
    
    func startCameraCapture() async {
        if #available(visionOS 2.0, *) {
            let provider = VisionOSCameraProvider()
            self.realProvider = provider
            
            // 绑定状态
            provider.$latestCameraFrame
                .sink { [weak self] frame in
                    DispatchQueue.main.async {
                        self?.latestCameraFrame = frame
                    }
                }
                .store(in: &cancellables)
            
            provider.$isActive
                .sink { [weak self] isActive in
                    DispatchQueue.main.async {
                        self?.isActive = isActive
                    }
                }
                .store(in: &cancellables)
            
            provider.$errorMessage
                .sink { [weak self] error in
                    DispatchQueue.main.async {
                        self?.errorMessage = error
                    }
                }
                .store(in: &cancellables)
            
            await provider.startCameraCapture()
        } else {
            await MainActor.run {
                self.errorMessage = "需要visionOS 2.0+才能访问摄像头"
            }
        }
    }
    
    func stopCameraCapture() {
        cancellables.removeAll()
        realProvider?.stopCameraCapture()
        
        DispatchQueue.main.async {
            self.isActive = false
            self.latestCameraFrame = nil
        }
    }
    
    deinit {
        stopCameraCapture()
    }
}

#endif 

