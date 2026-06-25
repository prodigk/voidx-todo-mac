import Foundation

enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }
}

struct RecurrenceRule: Codable, Identifiable, Equatable {
    var id: UUID
    var type: RecurrenceType
    var weekdays: [Int]
    var dayOfMonth: Int?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        type: RecurrenceType,
        weekdays: [Int] = [],
        dayOfMonth: Int? = nil,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.weekdays = weekdays
        self.dayOfMonth = dayOfMonth
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
}
