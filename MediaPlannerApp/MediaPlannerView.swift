import SwiftUI
import UserNotifications

struct MediaPlannerView: View {
    @StateObject private var planner = PlannerModel.shared
    @StateObject private var loader = VideoLoader()
    @StateObject private var audioLoader = AudioLoader() // ✅ добавлено
    @State private var showAlert = false
    @State private var alertMessage = ""

    var sortedReminders: [Reminder] {
        planner.allReminders.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                headerSection
                mediaPickerSection
                selectedInfoSection
                reminderButton
                Divider().padding(.vertical, 10)
                remindersList
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
            loader.loadVideos()
            audioLoader.loadAudioFiles()
            requestPermission()
        }
    }

    // MARK: - UI Sections

    private var headerSection: some View {
        VStack {
            Text("🎬 Choose media and reminder time")
                .font(.headline)
                .padding(.top)

            DatePicker("Choose Date and Time",
                       selection: $planner.selectedDate,
                       displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .padding()

            Picker("Media Type", selection: $planner.mediaType) {
                Text("Video").tag("video" as String?)
                Text("Audio").tag("audio" as String?)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    private var mediaPickerSection: some View {
        Group {
            if planner.mediaType == "video" {
                videoScrollSection
            } else if planner.mediaType == "audio" {
                audioScrollSection
            }
        }
    }

    private var videoScrollSection: some View {
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
                                    ? .accentColor : .primary
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 110)
    }

    private var audioScrollSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(audioLoader.audioFiles) { audio in
                    Button {
                        planner.selectedMediaName = audio.fileName
                    } label: {
                        VStack(spacing: 6) {
                            // 🎵 Миниатюра
                            if let thumb = audio.thumbnail {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                planner.selectedMediaName == audio.fileName
                                                ? Color.pink.opacity(0.6)
                                                : Color.clear,
                                                lineWidth: 1.5
                                            )
                                            .shadow(
                                                color: planner.selectedMediaName == audio.fileName
                                                ? .pink.opacity(0.5)
                                                : .clear,
                                                radius: 5
                                            )
                                    )
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(12)
                                    Image(systemName: "music.note")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            // 🎶 Название и длительность
                            Text(audio.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 90)
                            Text(audio.duration)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(planner.selectedMediaName == audio.fileName
                                      ? Color.pink.opacity(0.15)
                                      : Color.gray.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 130)
    }


    private var selectedInfoSection: some View {
        VStack(spacing: 5) {
            Text("🗓 Planned for \(planner.formattedDateAndTime())")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let name = planner.selectedMediaName {
                Text("Selected: \(name)")
                    .font(.headline)
            }
        }
    }

    private var reminderButton: some View {
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
    }

    private var remindersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 Your Bookings")
                .font(.title3.bold())
                .foregroundStyle(.linearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                .padding(.bottom, 5)

            if sortedReminders.isEmpty {
                Text("No reminders yet.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedReminders) { reminder in
                        HStack(spacing: 12) {
                            // 🎞 Миниатюра или иконка
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: reminder.mediaType == "video"
                                                ? [.purple.opacity(0.6), .blue.opacity(0.6)]
                                                : [.pink.opacity(0.7), .orange.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 65, height: 65)
                                    .shadow(color: .white.opacity(0.2), radius: 6, x: 0, y: 2)

                                Image(systemName: reminder.mediaType == "video" ? "film.fill" : "music.note.list")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.mediaName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(planner.formatDate(reminder.date))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()

                            // ▶️ Кнопка воспроизведения
                            Button(action: { playMedia(reminder) }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.linearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .pink.opacity(0.6), radius: 5)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(colors: [.pink.opacity(0.6), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 3)
                        )
                        .padding(.horizontal, 5)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }


    // MARK: - Helpers
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

        // 🧩 Проверка на дубликаты
        if planner.allReminders.contains(where: {
            $0.mediaName == name &&
            $0.mediaType == type &&
            abs($0.date.timeIntervalSince(planner.selectedDate)) < 1 // то же время (с точностью до секунды)
        }) {
            alertMessage = "⚠️ Reminder for \(name) at this time already exists!"
            showAlert = true
            return
        }

        // 🕑 Создание уведомления
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
