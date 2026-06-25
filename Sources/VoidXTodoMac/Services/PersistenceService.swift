import Foundation

struct AppData: Codable {
    var todos: [TodoItem]
    var notes: [NoteItem]
}

enum PersistenceService {
    private static let fileName = "voidx-todo-data.json"

    static func load() throws -> AppData? {
        let url = try dataURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppData.self, from: data)
    }

    static func save(_ appData: AppData) throws {
        let url = try dataURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(appData)
        try data.write(to: url, options: [.atomic])
    }

    private static func dataURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("VoidXTodoMac", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
