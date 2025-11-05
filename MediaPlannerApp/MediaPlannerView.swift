import SwiftUI
import UserNotifications

struct MediaPlannerView: View {
    @StateObject private var planner = PlannerModel.shared
    @StateObject private var loader = VideoLoader() // 👈 загрузчик видео
    @State private var allAudios: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    var sortedReminders: [Reminder] {
        planner.allReminders.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("🎬 Choose media and reminder time")
                    .font(.headline)
                    .padding(.top)

                // Date & Time picker
                DatePicker(
                    "Choose Date and Time",
                    selection: $planner.selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()

                // Media type picker
                Picker("Media Type", selection: $planner.mediaType) {
                    Text("Video").tag("video" as String?)
                    Text("Audio").tag("audio" as String?)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Media name picker
                if let type = planner.mediaType {
                    if type == "video" {
                        // 🎥 Список видео с превью
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(loader.videos) { video in
                                    Button {
                                        planner.selectedMediaName = video.fileName
                                    } label: {
                                        VStack {
                                            if let thumb = video.thumbnail {
                                                Image(uiImage: thumb)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 60)
                                                    .cornerRadius(8)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 100, height: 60)
                                                    .cornerRadius(8)
                                            }

                                            Text(video.name)
                                                .font(.caption)
                                                .foregroundColor(
                                                    planner.selectedMediaName == video.fileName
                                                    ? .accentColor
                                                    : .primary
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 110)

                    } else {
                        // 🎵 Picker для аудио
                        Picker("Choose Audio", selection: $planner.selectedMediaName) {
                            ForEach(allAudios, id: \.self) { name in
                                Text(name).tag(name as String?)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                }

                // Info section
                Text("🗓 Planned for \(planner.formattedDateAndTime())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let name = planner.selectedMediaName {
                    Text("Selected: \(name)")
                        .font(.headline)
                }

                // Reminder button
                Button(action: scheduleReminder) {
                    Label("🔔 Set Reminder", systemImage: "bell.badge.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 20)
                }

                Divider().padding(.vertical, 10)

                // 📋 Your bookings
                VStack(alignment: .leading, spacing: 8) {
                    Text("📋 Your Bookings")
                        .font(.headline)

                    if sortedReminders.isEmpty {
                        Text("No reminders yet.")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(sortedReminders) { reminder in
                            HStack {
                                Image(systemName: reminder.mediaType == "video" ? "film" : "music.note")
                                    .foregroundColor(reminder.mediaType == "video" ? .purple : .blue)
                                VStack(alignment: .leading) {
                                    Text(reminder.mediaName)
                                        .font(.headline)
                                    Text(planner.formatDate(reminder.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: { playMedia(reminder) }) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Planner")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Reminder"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear {
            loader.loadVideos()     // ✅ загружаем список видео
            loadMedia()             // ✅ загружаем аудио
            requestPermission()
        }
    }

    // MARK: - Helpers
    private func loadMedia() {
        let fm = FileManager.default
        var foundAudios: [String] = []

        if let resourcePath = Bundle.main.resourcePath {
            let mediaPath = resourcePath + "/Media"
            if let mediaFiles = try? fm.contentsOfDirectory(atPath: mediaPath) {
                foundAudios = mediaFiles.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") }
            }
        }

        allAudios = Array(Set(foundAudios)).sorted()
    }

    private func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print(granted ? "✅ Notifications allowed" : "⚠️ Notifications denied")
            }
    }

    private func scheduleReminder() {
        guard let name = planner.selectedMediaName,
              let type = planner.mediaType else {
            alertMessage = "Please choose both media type and file before setting a reminder."
            showAlert = true
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🎬 Media Reminder"
        content.body = "It's time for your \(type): \(name)"
        content.sound = .default
        content.userInfo = ["mediaType": type, "mediaName": name]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: planner.selectedDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "❌ Error: \(error.localizedDescription)"
                } else {
                    planner.addReminder(date: planner.selectedDate, type: type, name: name)
                    alertMessage = "✅ Reminder set for \(planner.formattedDateAndTime())"
                }
                showAlert = true
            }
        }
    }

    private func playMedia(_ reminder: Reminder) {
        print("▶ Playing \(reminder.mediaName)")
    }
}

#Preview {
    NavigationView {
        MediaPlannerView()
    }
}
