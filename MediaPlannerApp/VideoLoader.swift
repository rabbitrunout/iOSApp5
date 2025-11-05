import Foundation
import Combine
import AVFoundation
import UIKit

@MainActor
class VideoLoader: ObservableObject {
    @Published var videos: [Video] = []

    func loadVideos() {
        Task {
            guard let resourcePath = Bundle.main.resourcePath else {
                print("❌ Resource path not found")
                return
            }

            let fileManager = FileManager.default
            do {
                let items = try fileManager.contentsOfDirectory(atPath: resourcePath)
                print("📂 Files in main bundle:", items)

                // 🟢 Ищем все mp4/m4v файлы, включая вложенные
                let mediaFiles = items.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".m4v") }

                // Если не найдено — попробуем Media/
                var allVideos: [String] = mediaFiles
                let mediaPath = resourcePath + "/Media"
                if let mediaItems = try? fileManager.contentsOfDirectory(atPath: mediaPath) {
                    let mediaVideos = mediaItems.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".m4v") }
                    allVideos.append(contentsOf: mediaVideos)
                }

                if allVideos.isEmpty {
                    print("⚠️ No video files found in bundle or Media folder")
                    return
                }

                var loaded: [Video] = []
                for file in allVideos.sorted() {
                    let url: URL
                    if FileManager.default.fileExists(atPath: resourcePath + "/Media/\(file)") {
                        url = URL(fileURLWithPath: resourcePath + "/Media/\(file)")
                    } else {
                        url = URL(fileURLWithPath: resourcePath + "/\(file)")
                    }

                    async let duration = getVideoDuration(for: url)
                    async let thumbnail = generateThumbnail(for: url)

                    let video = Video(
                        name: (file as NSString).deletingPathExtension,
                        fileName: file,
                        thumbnail: await thumbnail,
                        duration: await duration
                    )
                    loaded.append(video)
                }

                self.videos = loaded
                print("✅ Loaded \(loaded.count) videos")

            } catch {
                print("❌ Error loading videos: \(error)")
            }
        }
    }

    private func getVideoDuration(for url: URL) async -> String {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = Int(CMTimeGetSeconds(duration))
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } catch {
            return "--:--"
        }
    }

    private func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        return await withCheckedContinuation { continuation in
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    print("⚠️ Thumbnail error: \(error?.localizedDescription ?? "unknown")")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
