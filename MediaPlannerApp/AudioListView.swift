import SwiftUI

struct AudioListView: View {
    @StateObject private var loader = AudioLoader()
    @ObservedObject private var planner = PlannerModel.shared

    var body: some View {
        List(loader.audioFiles) { audio in // ✅ без "$"
            NavigationLink(destination: AudioPlayerView(fileName: audio.fileName)) {
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(audio.name)
                            .font(.headline)
                        Text(audio.duration)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("📅 \(planner.formattedDateAndTime())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Audio Files")
        .onAppear { loader.loadAudioFiles() }
    }
}

#Preview {
    NavigationView {
        AudioListView()
    }
}
