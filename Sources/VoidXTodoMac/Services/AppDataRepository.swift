import Foundation

protocol AppDataRepository {
    func load() throws -> AppData?
    func save(_ appData: AppData) throws
}

struct LocalAppDataRepository: AppDataRepository {
    func load() throws -> AppData? {
        try PersistenceService.load()
    }

    func save(_ appData: AppData) throws {
        try PersistenceService.save(appData)
    }
}
