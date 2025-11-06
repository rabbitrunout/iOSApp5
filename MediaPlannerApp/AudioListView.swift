import SwiftUI

struct AudioListView: View {
    @StateObject private var loader = AudioLoader()
    @ObservedObject private var planner = PlannerModel.shared

    var body: some View {
        VStack {
            if loader.audioFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.7))
                    Text("No audio files found 🎧")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Make sure your .mp3 or .wav files are inside the Media folder\nand added to your app target.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 60)
            } else {
                List(loader.audioFiles) { audio in
                    NavigationLink(destination: AudioPlayerView(fileName: audio.fileName)) {
                        HStack(spacing: 12) {
                            // 🎵 Миниатюра или иконка
                            if let thumb = audio.thumbnail {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(10)
                                    .shadow(color: .pink.opacity(0.3), radius: 4)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.15))
                                    Image(systemName: "music.note")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 60, height: 60)
                            }

                            // 🎧 Информация
                            VStack(alignment: .leading, spacing: 4) {
                                Text(audio.name)
                                    .font(.headline)
                                Text(audio.duration)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                if let reminder = planner.allReminders.first(where: { $0.mediaName == audio.fileName }) {
                                    Text("🔔 Reminder: \(planner.formatDate(reminder.date))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("🎵 Audio Files")
        .onAppear {
            loader.loadAudioFiles()
        }
    }
}

#Preview {
    NavigationView {
        AudioListView()
    }
}
