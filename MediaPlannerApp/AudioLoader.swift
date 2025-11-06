import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
class AudioLoader: ObservableObject {
    @Published var audioFiles: [Audio] = []

    func loadAudioFiles() {
        Task {
            guard let resourcePath = Bundle.main.resourcePath else {
                print("❌ Resource path not found")
                return
            }

            let fileManager = FileManager.default
            var found: [String] = []

            // 1️⃣ Ищем в Media/
            let mediaPath = resourcePath + "/Media"
            if let mediaItems = try? fileManager.contentsOfDirectory(atPath: mediaPath) {
                let mediaAudios = mediaItems.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") }
                print("🎧 Found in Media/:", mediaAudios)
                found.append(contentsOf: mediaAudios.map { "Media/" + $0 })
            } else {
                print("⚠️ Media folder not found at:", mediaPath)
            }

            // 2️⃣ Ищем в корне (на случай, если Media не скопирована)
            if let rootItems = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                let rootAudios = rootItems.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") }
                print("🎶 Found in root:", rootAudios)
                found.append(contentsOf: rootAudios)
            }

            if found.isEmpty {
                print("❌ No audio files found in bundle!")
                return
            }

            // ✅ 3️⃣ Сортировка по числовому порядку
            let sorted = found.sorted { a, b in
                let nameA = (a as NSString).lastPathComponent
                let nameB = (b as NSString).lastPathComponent
                let numA = Int(nameA.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                let numB = Int(nameB.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                if numA == numB {
                    return nameA < nameB
                } else {
                    return numA < numB
                }
            }

            // 4️⃣ Загружаем длительность и миниатюры
            var loaded: [Audio] = []
            for path in sorted {
                let url = URL(fileURLWithPath: resourcePath + "/" + path)
                async let duration = getAudioDuration(for: url)
                async let thumb = getAudioThumbnail(for: url)
                let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
                loaded.append(Audio(name: name,
                                    fileName: path,
                                    duration: await duration,
                                    thumbnail: await thumb))
            }

            await MainActor.run {
                self.audioFiles = loaded
                print("✅ Loaded \(loaded.count) audio files: \(loaded.map(\.fileName))")
            }
        }
    }

    // MARK: - Duration
    private func getAudioDuration(for url: URL) async -> String {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = Int(CMTimeGetSeconds(duration))
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } catch {
            return "--:--"
        }
    }

    // MARK: - Thumbnail
    private func getAudioThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        do {
            let metadata = try await asset.load(.commonMetadata)
            if let artworkItem = metadata.first(where: { $0.commonKey?.rawValue == "artwork" }) {
                let value = try await artworkItem.load(.value)
                if let data = value as? Data, let image = UIImage(data: data) {
                    return image
                }
            }
        } catch {
            print("⚠️ Failed to load audio metadata: \(error)")
        }

        // 🎨 Если нет обложки — создаём дефолтную
        let colors: [UIColor] = [.systemPink, .systemBlue, .systemPurple, .systemTeal]
        let randomColor = colors.randomElement() ?? .systemGray
        return createPlaceholderImage(color: randomColor)
    }

    // MARK: - Placeholder
    private func createPlaceholderImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 20).fill()

        let note = UIImage(systemName: "music.note.list")!
        note.withTintColor(.white, renderingMode: .alwaysOriginal)
            .draw(in: CGRect(x: 60, y: 60, width: 80, height: 80))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
