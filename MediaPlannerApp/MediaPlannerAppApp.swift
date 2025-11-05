import SwiftUI
import UserNotifications
import Combine   // ✅ нужно для ObservableObject и @Published

// MARK: - Модель для открытия медиа
struct MediaLaunchItem: Identifiable {
    let id = UUID()
    let type: String
    let name: String
}

@main
struct MediaPlannerAppApp: App {
    @StateObject private var planner = PlannerModel.shared
    @State private var launchedMedia: MediaLaunchItem?
    
    init() {
        // Назначаем делегата для уведомлений
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(planner)
                .onReceive(NotificationDelegate.shared.$selectedMedia) { media in
                    if let media = media {
                        launchedMedia = MediaLaunchItem(type: media.type, name: media.name)
                    }
                }
                .sheet(item: $launchedMedia) { media in
                    if media.type == "video" {
                        VideoPlayerView(fileName: media.name)
                    } else {
                        AudioPlayerView(fileName: media.name)
                    }
                }
        }
    }
}

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    @Published var selectedMedia: (type: String, name: String)?
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        if let type = info["mediaType"] as? String,
           let name = info["mediaName"] as? String {
            print("📩 Notification tapped: \(type) → \(name)")
            DispatchQueue.main.async {
                self.selectedMedia = (type, name)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}
