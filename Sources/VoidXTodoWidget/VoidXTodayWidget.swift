import AppIntents
import Foundation
import SwiftUI
import WidgetKit

private let widgetKind = "VoidXTodayWidget"

@main
struct VoidXTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        VoidXTodayWidget()
    }
}

struct VoidXTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: TodayTimelineProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(WidgetPalette.canvas, for: .widget)
        }
        .configurationDisplayName("VoidX Today")
        .description("오늘 남은 할 일을 보고 바로 완료합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct TodayEntry: TimelineEntry {
    let date: Date
    let occurrences: [WidgetTodoOccurrence]
}

private struct TodayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), occurrences: WidgetTodoSample.occurrences)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), occurrences: loadOccurrences()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [TodayEntry(date: now, occurrences: loadOccurrences())], policy: .after(refresh)))
    }

    private func loadOccurrences() -> [WidgetTodoOccurrence] {
        (try? WidgetTodoStorage.loadOccurrences(on: Date())) ?? []
    }
}

private struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: TodayEntry

    private var maxItems: Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemLarge:
            return 8
        default:
            return 5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if entry.occurrences.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(entry.occurrences.prefix(maxItems)) { occurrence in
                        WidgetTodoRow(occurrence: occurrence)
                    }
                }

                if entry.occurrences.count > maxItems {
                    Text("+\(entry.occurrences.count - maxItems) more")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(WidgetPalette.slate)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("VOIDX")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(WidgetPalette.deepGreen)
                Text("Today")
                    .font(.system(size: family == .systemSmall ? 20 : 24, weight: .regular))
                    .foregroundStyle(WidgetPalette.ink)
            }

            Spacer()

            Text("\(entry.occurrences.count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(WidgetPalette.deepGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(WidgetPalette.paleGreen, in: Capsule())

            Link(destination: URL(string: "voidxtodo://today")!) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WidgetPalette.canvas)
                    .frame(width: 26, height: 26)
                    .background(WidgetPalette.primary, in: Circle())
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Clear")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WidgetPalette.ink)
            Text("오늘 할 일이 없습니다.")
                .font(.system(size: 12))
                .foregroundStyle(WidgetPalette.slate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct WidgetTodoRow: View {
    let occurrence: WidgetTodoOccurrence

    var body: some View {
        HStack(spacing: 7) {
            Button(intent: CompleteTodoIntent(todoID: occurrence.todo.id.uuidString, occurrenceTimestamp: occurrence.occurrenceDate.timeIntervalSince1970)) {
                Image(systemName: "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WidgetPalette.actionBlue)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(priorityColor)
                .frame(width: 5, height: 5)

            VStack(alignment: .leading, spacing: 1) {
                Text(occurrence.todo.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)

                if !occurrence.todo.detail.isEmpty {
                    Text(occurrence.todo.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.slate)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Text(occurrence.occurrenceDate.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(WidgetPalette.slate)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(WidgetPalette.softStone.opacity(0.46), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(WidgetPalette.hairline, lineWidth: 1)
        }
    }

    private var priorityColor: Color {
        switch occurrence.todo.priority {
        case .low:
            return WidgetPalette.slate
        case .normal:
            return WidgetPalette.actionBlue
        case .high:
            return WidgetPalette.coral
        }
    }
}

struct CompleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Todo"
    static var description = IntentDescription("Marks a VoidX Todo item complete from the widget.")

    @Parameter(title: "Todo ID")
    var todoID: String

    @Parameter(title: "Occurrence Timestamp")
    var occurrenceTimestamp: Double

    init() {
        todoID = ""
        occurrenceTimestamp = 0
    }

    init(todoID: String, occurrenceTimestamp: Double) {
        self.todoID = todoID
        self.occurrenceTimestamp = occurrenceTimestamp
    }

    func perform() async throws -> some IntentResult {
        try WidgetTodoStorage.complete(todoID: todoID, occurrenceDate: Date(timeIntervalSince1970: occurrenceTimestamp))
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        return .result()
    }
}

private enum WidgetTodoStorage {
    private static let fileName = "voidx-todo-data.json"

    static func loadOccurrences(on day: Date) throws -> [WidgetTodoOccurrence] {
        let data = try loadData()
        return data.todos.compactMap { WidgetRecurrenceService.occurrence(for: $0, on: day) }
            .filter { !$0.isCompleted }
            .sorted(by: occurrenceSort)
    }

    static func complete(todoID: String, occurrenceDate: Date) throws {
        guard let id = UUID(uuidString: todoID) else { return }
        var data = try loadData()
        guard let index = data.todos.firstIndex(where: { $0.id == id }) else { return }

        let day = WidgetCalendarService.startOfDay(occurrenceDate)
        if data.todos[index].recurrenceRule != nil {
            if !data.todos[index].completedOccurrenceDates.contains(where: { WidgetCalendarService.isSameDay($0, day) }) {
                data.todos[index].completedOccurrenceDates.append(day)
            }
        } else {
            data.todos[index].isCompleted = true
            data.todos[index].completedAt = Date()
        }

        data.todos[index].updatedAt = Date()
        try saveData(data)
    }

    private static func loadData() throws -> WidgetAppData {
        let url = try dataURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return WidgetAppData(todos: [])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WidgetAppData.self, from: data)
    }

    private static func saveData(_ appData: WidgetAppData) throws {
        let url = try dataURL()
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

    private static func occurrenceSort(_ lhs: WidgetTodoOccurrence, _ rhs: WidgetTodoOccurrence) -> Bool {
        if lhs.todo.priority != rhs.todo.priority {
            return priorityRank(lhs.todo.priority) > priorityRank(rhs.todo.priority)
        }
        return lhs.occurrenceDate < rhs.occurrenceDate
    }

    private static func priorityRank(_ priority: WidgetTodoPriority) -> Int {
        switch priority {
        case .low:
            return 0
        case .normal:
            return 1
        case .high:
            return 2
        }
    }
}

private enum WidgetRecurrenceService {
    static func occurrence(for todo: WidgetTodoItem, on day: Date) -> WidgetTodoOccurrence? {
        if let rule = todo.recurrenceRule {
            guard matches(rule: rule, on: day) else { return nil }
            let occurrenceDate = WidgetCalendarService.mergingDay(day, timeFrom: todo.dueDate)
            return WidgetTodoOccurrence(
                todo: todo,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted(todo: todo, on: day)
            )
        }

        guard WidgetCalendarService.isSameDay(todo.dueDate, day) else { return nil }
        return WidgetTodoOccurrence(todo: todo, occurrenceDate: todo.dueDate, isCompleted: todo.isCompleted)
    }

    private static func isCompleted(todo: WidgetTodoItem, on day: Date) -> Bool {
        let normalizedDay = WidgetCalendarService.startOfDay(day)
        return todo.completedOccurrenceDates.contains { WidgetCalendarService.isSameDay($0, normalizedDay) }
    }

    private static func matches(rule: WidgetRecurrenceRule, on day: Date) -> Bool {
        guard rule.isActive else { return false }
        let normalizedDay = WidgetCalendarService.startOfDay(day)
        let start = WidgetCalendarService.startOfDay(rule.startDate)
        guard normalizedDay >= start else { return false }
        if let endDate = rule.endDate, normalizedDay > WidgetCalendarService.startOfDay(endDate) {
            return false
        }

        switch rule.type {
        case .daily:
            return true
        case .weekly:
            let weekday = WidgetCalendarService.calendar.component(.weekday, from: normalizedDay)
            return rule.weekdays.contains(weekday)
        case .monthly:
            let dayOfMonth = WidgetCalendarService.calendar.component(.day, from: normalizedDay)
            return dayOfMonth == rule.dayOfMonth
        }
    }
}

private enum WidgetCalendarService {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.firstWeekday = 2
        return calendar
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func mergingDay(_ day: Date, timeFrom timeSource: Date) -> Date {
        let time = calendar.dateComponents([.hour, .minute, .second], from: timeSource)
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: day
        ) ?? day
    }
}

private struct WidgetAppData: Codable {
    var todos: [WidgetTodoItem]

    enum CodingKeys: String, CodingKey {
        case todos
    }

    init(todos: [WidgetTodoItem]) {
        self.todos = todos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todos = try container.decodeIfPresent([WidgetTodoItem].self, forKey: .todos) ?? []
    }
}

private struct WidgetTodoItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: WidgetTodoPriority
    var categoryID: UUID?
    var recurrenceRule: WidgetRecurrenceRule?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var completedOccurrenceDates: [Date]
}

private struct WidgetTodoOccurrence: Identifiable, Equatable {
    var todo: WidgetTodoItem
    var occurrenceDate: Date
    var isCompleted: Bool

    var id: String {
        "\(todo.id.uuidString)-\(Int(occurrenceDate.timeIntervalSince1970))"
    }
}

private enum WidgetTodoPriority: String, Codable {
    case low
    case normal
    case high
}

private enum WidgetRecurrenceType: String, Codable {
    case daily
    case weekly
    case monthly
}

private struct WidgetRecurrenceRule: Codable, Equatable {
    var id: UUID
    var type: WidgetRecurrenceType
    var weekdays: [Int]
    var dayOfMonth: Int?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
}

private enum WidgetTodoSample {
    static let occurrences = [
        WidgetTodoOccurrence(
            todo: WidgetTodoItem(
                id: UUID(),
                title: "Plan today",
                detail: "Pick the important three.",
                dueDate: Date(),
                isCompleted: false,
                priority: .high,
                categoryID: nil,
                recurrenceRule: nil,
                createdAt: Date(),
                updatedAt: Date(),
                completedAt: nil,
                completedOccurrenceDates: []
            ),
            occurrenceDate: Date(),
            isCompleted: false
        )
    ]
}

private enum WidgetPalette {
    static let primary = Color(hex: 0x17171c)
    static let ink = Color(hex: 0x212121)
    static let deepGreen = Color(hex: 0x003c33)
    static let canvas = Color.white
    static let softStone = Color(hex: 0xeeece7)
    static let paleGreen = Color(hex: 0xedfce9)
    static let hairline = Color(hex: 0xd9d9dd)
    static let slate = Color(hex: 0x75758a)
    static let coral = Color(hex: 0xff7759)
    static let actionBlue = Color(hex: 0x1863dc)
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
