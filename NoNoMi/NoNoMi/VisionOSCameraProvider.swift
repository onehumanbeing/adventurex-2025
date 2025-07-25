import SwiftUI
import ARKit
import RealityKit

#if !os(iOS)
// visionOS Enterprise Camera Provider
// 注意：此代码需要Apple Enterprise Developer Account和特殊权限才能访问主相机
@available(visionOS 1.0, *)
class VisionOSCameraProvider: ObservableObject {
    @Published var latestCameraFrame: UIImage?
    @Published var isActive: Bool = false
    @Published var errorMessage: String?
    
    private var arkitSession: ARKitSession?
    private var cameraFrameProvider: CameraFrameProvider?
    private var frameProcessingTask: Task<Void, Never>?
    
    init() {
        print("[VisionOSCameraProvider] 初始化")
    }
    
    // 启动相机捕获（需要Enterprise权限）
    func startCameraCapture() async {
        print("[VisionOSCameraProvider] 尝试启动相机捕获...")
        
        do {
            // 检查是否支持CameraFrameProvider
            guard CameraFrameProvider.isSupported else {
                let error = "CameraFrameProvider 在此设备上不支持"
                print("[VisionOSCameraProvider] \(error)")
                await MainActor.run {
                    self.errorMessage = error
                }
                return
            }
            
            // 创建ARKitSession和CameraFrameProvider
            let session = ARKitSession()
            let provider = CameraFrameProvider()
            
            // 请求权限
            print("[VisionOSCameraProvider] 请求相机访问权限...")
            let authorizationResult = await session.queryAuthorization(for: [.cameraAccess])
            
            for (authType, status) in authorizationResult {
                print("[VisionOSCameraProvider] 权限类型: \(authType), 状态: \(status)")
                if status != .allowed {
                    let error = "相机访问权限被拒绝: \(authType)"
                    print("[VisionOSCameraProvider] \(error)")
                    await MainActor.run {
                        self.errorMessage = error
                    }
                    return
                }
            }
            
            // 启动会话
            print("[VisionOSCameraProvider] 启动ARKitSession...")
            try await session.run([provider])
            
            // 存储引用
            self.arkitSession = session
            self.cameraFrameProvider = provider
            
            await MainActor.run {
                self.isActive = true
                self.errorMessage = nil
            }
            
            // 开始处理相机帧
            await processCameraFrameUpdates(provider: provider)
            
        } catch {
            let errorMsg = "启动相机捕获失败: \(error.localizedDescription)"
            print("[VisionOSCameraProvider] \(errorMsg)")
            await MainActor.run {
                self.errorMessage = errorMsg
                self.isActive = false
            }
        }
    }
    
    // 停止相机捕获
    func stopCameraCapture() {
        print("[VisionOSCameraProvider] 停止相机捕获")
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
    
    // 处理相机帧更新
    private func processCameraFrameUpdates(provider: CameraFrameProvider) async {
        frameProcessingTask = Task {
            do {
                for await cameraFrame in provider.cameraFrameUpdates {
                    guard !Task.isCancelled else { break }
                    await self.handleCameraFrame(cameraFrame)
                }
            } catch {
                print("[VisionOSCameraProvider] 相机帧处理错误: \(error)")
                await MainActor.run {
                    self.errorMessage = "相机帧处理错误: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 处理单个相机帧
    @MainActor
    private func handleCameraFrame(_ frame: CameraFrame) async {
        guard let image = convertCameraFrameToUIImage(frame) else {
            print("[VisionOSCameraProvider] 无法转换相机帧为UIImage")
            return
        }
        
        print("[VisionOSCameraProvider] 获取到相机帧，尺寸: \(image.size)")
        self.latestCameraFrame = image
    }
    
    // 将CameraFrame转换为UIImage
    private func convertCameraFrameToUIImage(_ frame: CameraFrame) -> UIImage? {
        // 从CameraFrame获取CVPixelBuffer
        let pixelBuffer = frame.sample.pixelBuffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("[VisionOSCameraProvider] 无法创建CGImage from CameraFrame")
            return nil
        }
        
        // 创建UIImage，确保正确的方向
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        return image
    }
    
    deinit {
        stopCameraCapture()
    }
}

// 模拟器和非Enterprise版本的占位符提供者
class MockVisionOSCameraProvider: ObservableObject {
    @Published var latestCameraFrame: UIImage?
    @Published var isActive: Bool = false
    @Published var errorMessage: String? = "需要Enterprise API权限访问真实相机"
    
    private var simulationTask: Task<Void, Never>?
    
    func startCameraCapture() async {
        await MainActor.run {
            self.isActive = true
            self.errorMessage = "使用模拟相机帧 (需要Enterprise API权限获取真实相机)"
        }
        
        simulationTask = Task {
            while !Task.isCancelled {
                let mockFrame = createMockCameraFrame()
                await MainActor.run {
                    self.latestCameraFrame = mockFrame
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }
    
    func stopCameraCapture() {
        simulationTask?.cancel()
        simulationTask = nil
        
        DispatchQueue.main.async {
            self.isActive = false
            self.latestCameraFrame = nil
        }
    }
    
    private func createMockCameraFrame() -> UIImage {
        let size = CGSize(width: 1920, height: 1440)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 创建动态渐变背景
            let time = Date().timeIntervalSince1970
            let hue1 = (sin(time * 0.5) + 1) / 2
            let hue2 = (cos(time * 0.3) + 1) / 2
            
            let color1 = UIColor(hue: hue1, saturation: 0.8, brightness: 0.9, alpha: 1.0)
            let color2 = UIColor(hue: hue2, saturation: 0.8, brightness: 0.7, alpha: 1.0)
            
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(origin: .zero, size: size)
            gradient.colors = [color1.cgColor, color2.cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            
            context.cgContext.saveGState()
            if let gradientImage = imageFromLayer(gradient) {
                gradientImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            // 添加文本信息
            let text = "Mock Camera Frame\nvisionOS需要Enterprise API\n获取真实相机数据"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2
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
            context.cgContext.restoreGState()
        }
    }
    
    private func imageFromLayer(_ layer: CALayer) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

#endif 