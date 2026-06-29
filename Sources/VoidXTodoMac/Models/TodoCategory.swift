import Foundation

struct TodoCategory: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var colorIndex: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum TodoCategoryPalette {
    static let count = 6
}
