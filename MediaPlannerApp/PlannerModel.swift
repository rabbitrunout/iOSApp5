import Foundation
import Combine
import SwiftUI

final class PlannerModel: ObservableObject {
    static let shared = PlannerModel()

    // MARK: - Основные свойства
    @Published var selectedDate: Date {
        didSet { saveDate() }
    }

    @Published var mediaType: String? = nil
    @Published var selectedMediaName: String? = nil
    @Published var allReminders: [Reminder] = [] {
        didSet { saveReminders() }
    }

    private let dateKey = "selectedPlannerDate"
    private let remindersKey = "allMediaReminders"

    // MARK: - Инициализация
    private init() {
        if let saved = UserDefaults.standard.object(forKey: dateKey) as? Date {
            selectedDate = saved
        } else {
            selectedDate = Date()
        }
        loadReminders()
    }

    // MARK: - Работа с датой
    private func saveDate() {
        UserDefaults.standard.set(selectedDate, forKey: dateKey)
    }

    func formattedDateAndTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Работа с напоминаниями
    func addReminder(date: Date, type: String, name: String) {
        let new = Reminder(id: UUID(), date: date, mediaType: type, mediaName: name)
        allReminders.append(new)
        saveReminders()
    }

    func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let saved = try? JSONDecoder().decode([Reminder].self, from: data) {
            allReminders = saved
        }
    }

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(allReminders) {
            UserDefaults.standard.set(data, forKey: remindersKey)
        }
    }

    func removeReminder(at offsets: IndexSet) {
        allReminders.remove(atOffsets: offsets)
        saveReminders()
    }
}
