//
//  VideoItem.swift
//  MediaPlannerApp
//
//  Created by Irina Saf on 2025-11-05.
//

import SwiftUI
import AVFoundation

// 🎥 Модель одного видеофайла
struct VideoItem: Identifiable {
    let id = UUID()
    let fileName: String
    let name: String
    let duration: String
    let thumbnail: UIImage?
}




