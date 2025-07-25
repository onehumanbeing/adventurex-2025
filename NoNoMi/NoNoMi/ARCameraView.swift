import SwiftUI
import RealityKit

#if os(iOS)
import ARKit
#endif

// 相机视图，在iOS上使用ARKit获取真实相机帧，在visionOS上使用截图
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
        // visionOS平台使用透明UIView，通过定时截图获取内容
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
        private var frameUpdateTimer: Timer?
        
        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            
            #if !os(iOS)
            // visionOS上使用定时截图作为替代方案
            print("[ARCameraView] 启动visionOS截图定时器")
            startScreenshotTimer()
            #else
            print("[ARCameraView] 初始化iOS ARKit代理")
            #endif
        }
        
        #if !os(iOS)
        // visionOS替代方案：定时截图
        private func startScreenshotTimer() {
            frameUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.captureScreenshot()
                }
            }
        }
        
        private func captureScreenshot() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("[ARCameraView] 无法获取窗口场景")
                return
            }
            
            let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
            let screenshot = renderer.image { context in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
            }
            
            print("[ARCameraView] 截图成功，尺寸: \(screenshot.size)")
            parent.latestFrame = screenshot
        }
        #endif
        
        deinit {
            frameUpdateTimer?.invalidate()
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
            print("[ARCameraView] 获取到相机帧，尺寸: \(cameraImage.size)")
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