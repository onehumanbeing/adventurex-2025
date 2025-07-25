//
//  StatusData.swift
//  NoNoMiProd
//
//  Created by Henry on 26/7/2025.
//

import Foundation

struct StatusData: Codable, Equatable {
    let voice: String
    let timestamp: Int
    let html: String
    let danmu_text: String
    let height: Int
    let width: Int
} 