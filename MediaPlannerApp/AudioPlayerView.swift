import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let fileName: String
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 25) {
            Text(fileName)
                .font(.title2)
                .bold()
                .padding(.top, 40)

            HStack(spacing: 60) {
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(isPlaying ? Color.orange : Color.green)
                }

                Button(action: stopAudio) {
                    Image(systemName: "stop.circle.fill")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundStyle(Color.red)
                }
            }

            Spacer()
        }
        .onAppear { setupPlayer() }
        .onDisappear { stopAudio() }
        .navigationTitle("Audio Player")
        .padding()
    }

    private func setupPlayer() {
        if let path = Bundle.main.path(forResource: fileName, ofType: nil) {
            let url = URL(fileURLWithPath: path)
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
            } catch {
                print("❌ Error loading audio file: \(error)")
            }
        } else {
            print("⚠️ Audio file not found in bundle: \(fileName)")
        }
    }

    private func togglePlay() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    private func stopAudio() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
    }
}

#Preview {
    AudioPlayerView(fileName: "test.mp3")
}
