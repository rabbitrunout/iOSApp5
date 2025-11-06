import Foundation
import UIKit

struct Audio: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let duration: String
    let thumbnail: UIImage?
}
