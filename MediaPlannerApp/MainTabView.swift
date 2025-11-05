import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                VideoListView()
            }
            .tabItem {
                Label("Videos", systemImage: "film")
            }

            NavigationView {
                AudioListView()
            }
            .tabItem {
                Label("Audio", systemImage: "music.note.list")
            }

            NavigationView {
                MediaPlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    MainTabView()
}
