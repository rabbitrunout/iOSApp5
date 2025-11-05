import SwiftUI

struct RemindersListView: View {
    @ObservedObject private var planner = PlannerModel.shared

    var body: some View {
        List {
            ForEach(planner.allReminders.sorted(by: { $0.date < $1.date })) { reminder in
                HStack {
                    VStack(alignment: .leading) {
                        Text(reminder.mediaName)
                            .font(.headline)
                        Text(reminder.mediaType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(format(reminder.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: reminder.mediaType == "video" ? "film" : "music.note")
                        .foregroundColor(reminder.mediaType == "video" ? .purple : .blue)
                }
                .padding(.vertical, 6)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("My Bookings")
    }

    private func delete(at offsets: IndexSet) {
        planner.allReminders.remove(atOffsets: offsets)
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

#Preview {
    NavigationView {
        RemindersListView()
    }
}
