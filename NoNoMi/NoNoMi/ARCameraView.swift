import SwiftUI
import RealityKit
import ARKit
import Combine

// 相机视图，在iOS上使用ARKit，在visionOS上使用Enterprise CameraFrameProvider获取真实相机帧
struct ARCameraView: UIViewRepresentable {
    @Binding var latestFrame: UIImage?
    @ObservedObject var apiService: APIService
    
    func makeUIView(context: Context) -> UIView {
        #if os(iOS)
        // iOS平台使用ARKit获取真实相机帧
        print("[ARCameraView] 初始化ARView (iOS)")
        let arView = ARView(frame: .zero)
        
        // 配置AR会话以获取最佳相机帧
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats
            .filter { $0.imageResolution.width >= 1920 } // 优先选择高分辨率
            .first ?? ARWorldTrackingConfiguration.supportedVideoFormats.first!
        
        print("[ARCameraView] 视频格式: \(configuration.videoFormat)")
        
        arView.session.delegate = context.coordinator
        arView.session.run(configuration)
        
        return arView
        #else
        // visionOS平台使用透明UIView，相机帧通过VisionOSCameraProvider获取
        print("[ARCameraView] 初始化UIView (visionOS)")
        let placeholderView = UIView()
        placeholderView.backgroundColor = UIColor.clear
        return placeholderView
        #endif
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新视图
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARCameraView
        
        #if !os(iOS)
        // visionOS相机提供者
        private var cameraProvider: AnyObject? // 可以是VisionOSCameraProvider或MockVisionOSCameraProvider
        private var observationTask: Task<Void, Never>?
        private var cancellables: Set<AnyCancellable> = []
        #endif
        
        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            
            #if !os(iOS)
            // visionOS上启动相机捕获
            print("[ARCameraView] 启动visionOS相机捕获")
            setupVisionOSCamera()
            #else
            print("[ARCameraView] 初始化iOS ARKit代理")
            #endif
        }
        
        #if !os(iOS)
        private func setupVisionOSCamera() {
            // 尝试使用真实的Enterprise Camera Provider
            if #available(visionOS 1.0, *) {
                // 检查是否支持CameraFrameProvider（需要Enterprise权限）
                if CameraFrameProvider.isSupported {
                    print("[ARCameraView] 使用Enterprise CameraFrameProvider")
                    let provider = VisionOSCameraProvider()
                    self.cameraProvider = provider
                    
                    // 观察相机帧更新
                    observationTask = Task {
                        await provider.startCameraCapture()
                    }
                    
                    // 监听相机帧更新
                    observeProviderUpdates(provider)
                    
                } else {
                    print("[ARCameraView] CameraFrameProvider不支持，使用Mock Provider")
                    setupMockCamera()
                }
            } else {
                setupMockCamera()
            }
        }
        
        private func setupMockCamera() {
            let mockProvider = MockVisionOSCameraProvider()
            self.cameraProvider = mockProvider
            
            observationTask = Task {
                await mockProvider.startCameraCapture()
            }
            
            observeMockProviderUpdates(mockProvider)
        }
        
        private func observeProviderUpdates(_ provider: VisionOSCameraProvider) {
            // 使用Combine来观察相机帧更新
            provider.$latestCameraFrame
                .compactMap { $0 }
                .sink { [weak self] frame in
                    DispatchQueue.main.async {
                        print("[ARCameraView] 收到Enterprise相机帧，尺寸: \(frame.size)")
                        self?.parent.latestFrame = frame
                    }
                }
                .store(in: &cancellables)
        }
        
        private func observeMockProviderUpdates(_ provider: MockVisionOSCameraProvider) {
            provider.$latestCameraFrame
                .compactMap { $0 }
                .sink { [weak self] frame in
                    DispatchQueue.main.async {
                        print("[ARCameraView] 收到Mock相机帧，尺寸: \(frame.size)")
                        self?.parent.latestFrame = frame
                    }
                }
                .store(in: &cancellables)
        }
        #endif
        
        deinit {
            #if !os(iOS)
            observationTask?.cancel()
            cancellables.removeAll()
            
            if let provider = cameraProvider as? VisionOSCameraProvider {
                provider.stopCameraCapture()
            } else if let mockProvider = cameraProvider as? MockVisionOSCameraProvider {
                mockProvider.stopCameraCapture()
            }
            #endif
        }
    }
}

#if os(iOS)
// iOS平台的ARSessionDelegate扩展
extension ARCameraView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 获取相机帧并转换为UIImage
        guard let cameraImage = frame.toCameraImage() else {
            print("[ARCameraView] 无法转换ARFrame为UIImage")
            return
        }
        
        DispatchQueue.main.async {
            print("[ARCameraView] 获取到iOS相机帧，尺寸: \(cameraImage.size)")
            self.parent.latestFrame = cameraImage
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("[ARCameraView] AR Session 失败: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("[ARCameraView] AR Session 被中断")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("[ARCameraView] AR Session 中断结束")
    }
}

// iOS平台的ARFrame扩展
extension ARFrame {
    func toCameraImage() -> UIImage? {
        let pixelBuffer = self.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("[ARFrame] 无法创建CGImage")
            return nil
        }
        
        // 确保图像方向正确
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        print("[ARFrame] 转换成功，图像尺寸: \(image.size)")
        return image
    }
}
#endif 