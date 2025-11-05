import Foundation

struct Reminder: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var mediaType: String
    var mediaName: String
}
