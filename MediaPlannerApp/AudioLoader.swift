import Foundation
import AVFoundation
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
            do {
                // Проверяем файлы в корне и в папке Media
                var found: [String] = []

                let rootItems = try fileManager.contentsOfDirectory(atPath: resourcePath)
                found.append(contentsOf: rootItems.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") })

                let mediaPath = resourcePath + "/Media"
                if let mediaItems = try? fileManager.contentsOfDirectory(atPath: mediaPath) {
                    found.append(contentsOf: mediaItems.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") })
                }

                print("🎶 Found audio files:", found)
                if found.isEmpty {
                    print("⚠️ No audio files found")
                    return
                }

                var loaded: [Audio] = []
                for file in found {
                    let url: URL
                    if FileManager.default.fileExists(atPath: resourcePath + "/Media/\(file)") {
                        url = URL(fileURLWithPath: resourcePath + "/Media/\(file)")
                    } else {
                        url = URL(fileURLWithPath: resourcePath + "/\(file)")
                    }

                    async let duration = getAudioDuration(for: url)
                    let name = (file as NSString).deletingPathExtension

                    loaded.append(Audio(name: name, fileName: file, duration: await duration))
                }

                self.audioFiles = loaded
                print("✅ Loaded \(loaded.count) audio tracks")

            } catch {
                print("❌ Error loading audio files: \(error)")
            }
        }
    }

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
}
