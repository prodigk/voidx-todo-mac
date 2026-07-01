import Foundation

enum TodoScheduleScope: String, Codable, CaseIterable, Identifiable {
    case day
    case week

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        }
    }
}

struct TodoItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: TodoPriority
    var categoryID: UUID?
    var scheduleScope: TodoScheduleScope
    var recurrenceRule: RecurrenceRule?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var completedOccurrenceDates: [Date]

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        dueDate: Date,
        isCompleted: Bool = false,
        priority: TodoPriority = .normal,
        categoryID: UUID? = nil,
        scheduleScope: TodoScheduleScope = .day,
        recurrenceRule: RecurrenceRule? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        completedOccurrenceDates: [Date] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.categoryID = categoryID
        self.scheduleScope = scheduleScope
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.completedOccurrenceDates = completedOccurrenceDates
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case detail
        case dueDate
        case isCompleted
        case priority
        case categoryID
        case scheduleScope
        case recurrenceRule
        case createdAt
        case updatedAt
        case completedAt
        case completedOccurrenceDates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decode(String.self, forKey: .detail)
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        priority = try container.decode(TodoPriority.self, forKey: .priority)
        categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        scheduleScope = try container.decodeIfPresent(TodoScheduleScope.self, forKey: .scheduleScope) ?? .day
        recurrenceRule = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        completedOccurrenceDates = try container.decodeIfPresent([Date].self, forKey: .completedOccurrenceDates) ?? []
    }
}

struct TodoOccurrence: Identifiable, Equatable {
    var todo: TodoItem
    var occurrenceDate: Date
    var isCompleted: Bool
    var completedAt: Date?

    var id: String {
        "\(todo.id.uuidString)-\(Int(occurrenceDate.timeIntervalSince1970))"
    }

    var isRecurring: Bool {
        todo.recurrenceRule != nil
    }
}
