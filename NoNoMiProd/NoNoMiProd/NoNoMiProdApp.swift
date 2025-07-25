//
//  NoNoMiProdApp.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import SwiftUI

@main
struct NoNoMiProdApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 给 2D 系统提供窗口支持（iOS/macOS）

        WindowGroup(id: "MainWindow") {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.15, height: 0.5, depth: 0.03, in: .meters)
    }
}
