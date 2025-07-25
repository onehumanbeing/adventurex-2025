import SwiftUI
import RealityKit
import ARKit

// ARKit相机视图，用于在visionOS上访问相机数据
struct ARCameraView: UIViewRepresentable {
    @Binding var latestFrame: ARFrame?
    @ObservedObject var apiService: APIService
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        
        // 设置会话代理
        arView.session.delegate = context.coordinator
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 更新AR视图
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARCameraView
        
        init(_ parent: ARCameraView) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 在主线程更新最新帧
            DispatchQueue.main.async {
                self.parent.latestFrame = frame
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
        }
    }
}

// ARFrame转UIImage的扩展
extension ARFrame {
    func toCameraImage() -> UIImage? {
        let pixelBuffer = self.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
} 