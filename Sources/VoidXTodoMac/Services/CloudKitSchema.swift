import Foundation

enum CloudKitSchema {
    static let containerIdentifier = "iCloud.com.voidx.todo"

    enum RecordType {
        static let todo = "Todo"
        static let category = "Category"
        static let note = "Note"
    }

    enum Field {
        static let title = "title"
        static let detail = "detail"
        static let body = "body"
        static let dueDate = "dueDate"
        static let isCompleted = "isCompleted"
        static let priority = "priority"
        static let categoryID = "categoryID"
        static let scheduleScope = "scheduleScope"
        static let recurrenceRuleJSON = "recurrenceRuleJSON"
        static let completedAt = "completedAt"
        static let completedOccurrenceDatesJSON = "completedOccurrenceDatesJSON"
        static let colorIndex = "colorIndex"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let deletedAt = "deletedAt"
    }
}
