import Foundation

struct TodoItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: TodoPriority
    var categoryID: UUID?
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
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.completedOccurrenceDates = completedOccurrenceDates
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
