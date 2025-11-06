import SwiftUI

struct AudioListView: View {
    @StateObject private var loader = AudioLoader()
    @ObservedObject private var planner = PlannerModel.shared

    var body: some View {
        List(loader.audioFiles) { audio in
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    // 🎵 Миниатюра
                    if let thumb = audio.thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 60)
                            .cornerRadius(10)
                            .clipped()
                            .shadow(color: .pink.opacity(0.4), radius: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 60)
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(audio.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(audio.duration)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        // 🕒 Будущее напоминание
                        if let reminder = planner.allReminders.first(where: {
                            $0.mediaName == audio.fileName && $0.mediaType == "audio"
                        }) {
                            if reminder.date > Date() {
                                HStack(spacing: 5) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.pink)
                                    Text(planner.formatDate(reminder.date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    Spacer()
                }

                // 🟣 Кнопка добавления напоминания
                if planner.allReminders.first(where: {
                    $0.mediaName == audio.fileName && $0.mediaType == "audio"
                }) == nil {
                    Button {
                        planner.selectedMediaName = audio.fileName
                        planner.mediaType = "audio"
                        planner.selectedDate = Date().addingTimeInterval(60 * 10) // +10 минут
                        planner.addReminder(date: planner.selectedDate, type: "audio", name: audio.fileName)
                    } label: {
                        Text("+ Add Reminder")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.pink.opacity(0.15))
                            .foregroundColor(.pink)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 10) {
                        Button("Update") {
                            planner.selectedMediaName = audio.fileName
                            planner.mediaType = "audio"
                            planner.selectedDate = Date().addingTimeInterval(60 * 15) // переносим на 15 мин
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)

                        Button("Delete") {
                            planner.allReminders.removeAll {
                                $0.mediaName == audio.fileName && $0.mediaType == "audio"
                            }
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.white.opacity(0.95))
        }
        .listStyle(.plain)
        .navigationTitle("🎵 Audio Files")
        .onAppear { loader.loadAudioFiles() }
    }
}

#Preview {
    NavigationView {
        AudioListView()
    }
}
