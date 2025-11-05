import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let fileName: String
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.volume = 1.0  // 🔊 включает звук
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player?.seek(to: .zero)
                    }
                    .ignoresSafeArea()
            } else {
                Text("❌ Video not found: \(fileName)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    VideoPlayerView(fileName: "SampleVideo.mp4")
}
