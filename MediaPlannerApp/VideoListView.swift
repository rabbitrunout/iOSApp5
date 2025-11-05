import SwiftUI

// ✅ Обёртка для sheet, безопасная альтернатива String
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

struct VideoListView: View {
    @StateObject private var loader = VideoLoader()
    @ObservedObject private var planner = PlannerModel.shared
    @State private var showDatePickerFor: IdentifiableString? = nil
    @State private var newDate: Date = Date()

    var body: some View {
        List {
            ForEach(loader.videos) { video in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        // 🎞 Миниатюра
                        if let thumb = video.thumbnail {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 60)
                                .cornerRadius(8)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 60)
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.name)
                                .font(.headline)
                            Text(video.duration)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            // 🔔 Показываем напоминание (будущее или истекшее)
                            if let reminder = planner.allReminders.first(where: { matches(reminder: $0, video: video) }) {
                                if reminder.date > Date() {
                                    // 🔔 Будущее
                                    HStack(spacing: 5) {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(.accentColor)
                                        Text(planner.formatDate(reminder.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    // ⏰ Прошедшее
                                    HStack(spacing: 5) {
                                        Image(systemName: "clock.badge.checkmark.fill")
                                            .foregroundColor(.gray)
                                        Text("Expired: \(planner.formatDate(reminder.date))")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                Text("🔕 No reminder set")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }

                    // 👇 Кнопки под каждым видео
                    HStack {
                        if let existing = planner.allReminders.first(where: { matches(reminder: $0, video: video) }) {
                            // ⏰ Обновить
                            Button("⏰ Update") {
                                showDatePickerFor = IdentifiableString(value: video.fileName)
                                newDate = existing.date
                            }
                            .buttonStyle(.bordered)

                            // 🗑 Удалить
                            Button(role: .destructive) {
                                if let index = planner.allReminders.firstIndex(where: { $0.id == existing.id }) {
                                    planner.allReminders.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        } else {
                            // ➕ Добавить новое
                            Button("➕ Add Reminder") {
                                showDatePickerFor = IdentifiableString(value: video.fileName)
                                newDate = Date()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.leading, 100)
                }
                .padding(.vertical, 4)
                // ✨ Подсветка видео с будущим напоминанием
                .background(planner.allReminders.contains(where: { matches(reminder: $0, video: video) && $0.date > Date() }) ?
                            Color.accentColor.opacity(0.08) : Color.clear)
                .cornerRadius(10)
            }
        }
        .navigationTitle("Videos")
        .onAppear { loader.loadVideos() }

        // MARK: - Sheet
        .sheet(item: $showDatePickerFor) { item in
            VStack(spacing: 16) {
                Text("📅 Set reminder for \(item.value)")
                    .font(.headline)

                DatePicker(
                    "Choose Date & Time",
                    selection: $newDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()

                Button("Save Reminder") {
                    planner.addReminder(date: newDate, type: "video", name: item.value)
                    showDatePickerFor = nil
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel", role: .cancel) {
                    showDatePickerFor = nil
                }
            }
            .padding()
        }
    }

    // MARK: - Helper
    /// Сравнивает напоминание и видео, игнорируя расширение файла
    private func matches(reminder: Reminder, video: Video) -> Bool {
        let reminderName = reminder.mediaName.replacingOccurrences(of: ".mp4", with: "")
        let videoName = video.fileName.replacingOccurrences(of: ".mp4", with: "")
        return reminderName == videoName
    }
}

#Preview {
    NavigationView {
        VideoListView()
    }
}
