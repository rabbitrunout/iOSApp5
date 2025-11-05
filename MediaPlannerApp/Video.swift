import Foundation
import UIKit

struct Video: Identifiable, Equatable {
    let id = UUID()
    let name: String           // Название без расширения
    let fileName: String       // Полное имя файла (например, "clip1.mp4")
    let thumbnail: UIImage?    // Превью кадра
    let duration: String       // Формат времени (мм:сс)
}
