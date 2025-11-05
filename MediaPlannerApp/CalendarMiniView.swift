import SwiftUI

struct CalendarMiniView: View {
    @ObservedObject var planner = PlannerModel.shared
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(formattedMonth(selectedDate))
                    .font(.headline)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            let days = makeDays(for: selectedDate)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { day in
                    VStack {
                        Text("\(calendar.component(.day, from: day))")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(isToday(day) ? Color.accentColor.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSelected(day) ? Color.accentColor : .clear, lineWidth: 2)
                            )

                        if hasReminder(on: day) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .transition(.scale)
                        }
                    }
                    .onTapGesture { selectedDate = day }
                }
            }
            .padding(.horizontal)
        }
        .onAppear { planner.loadReminders() }
    }

    // MARK: - Helpers

    private func formattedMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func makeDays(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else { return [] }

        var days: [Date] = []
        var current = firstWeek.start
        while current <= lastWeek.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }

    private func hasReminder(on date: Date) -> Bool {
        planner.allReminders.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = next
        }
    }

    private func previousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = prev
        }
    }
}


#Preview {
    StateWrapper()
}

private struct StateWrapper: View {
    @State var tempDate = Date()
    var body: some View {
        CalendarMiniView(selectedDate: $tempDate)
    }
}

