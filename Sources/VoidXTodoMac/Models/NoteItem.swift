import Foundation

struct NoteItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var categoryID: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        categoryID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.categoryID = categoryID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
