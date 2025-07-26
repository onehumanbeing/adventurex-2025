import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var headAnchor: AnchorEntity?
    
    var body: some View {
        RealityView { content, attachments in
            let anchor = AnchorEntity(.head)
            anchor.anchoring.trackingMode = .continuous
            content.add(anchor)
//            anchor.name = "Head Anchor"
            
            if let debugAttachment = attachments.entity(for: "canvas") {
                // 调整位置，让视图更靠左，避免遮挡主视角
                debugAttachment.position = [-0.3, 0, -1.0] // 向左偏移0.3米
                anchor.addChild(debugAttachment)
            }
            
            headAnchor = anchor
        } attachments: {
            Attachment(id: "canvas") {
                ContentView()
            }
        }
    }
}
