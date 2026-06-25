import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var todos: [TodoItem] = []
    @Published private(set) var notes: [NoteItem] = []
    @Published var lastError: String?

    init() {
        load()
    }

    func addTodo(
        title: String,
        detail: String,
        dueDate: Date,
        priority: TodoPriority,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        todos.append(
            TodoItem(
                title: cleanTitle,
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: dueDate,
                priority: priority,
                recurrenceRule: recurrenceRule
            )
        )
        save()
    }

    func updateTodo(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        var updated = todo
        updated.updatedAt = Date()
        todos[index] = updated
        save()
    }

    func deleteTodo(id: UUID) {
        todos.removeAll { $0.id == id }
        save()
    }

    func toggleCompletion(_ occurrence: TodoOccurrence) {
        guard let index = todos.firstIndex(where: { $0.id == occurrence.todo.id }) else { return }
        let day = CalendarService.startOfDay(occurrence.occurrenceDate)

        if todos[index].recurrenceRule != nil {
            if let completedIndex = todos[index].completedOccurrenceDates.firstIndex(where: { CalendarService.isSameDay($0, day) }) {
                todos[index].completedOccurrenceDates.remove(at: completedIndex)
            } else {
                todos[index].completedOccurrenceDates.append(day)
            }
        } else {
            todos[index].isCompleted.toggle()
            todos[index].completedAt = todos[index].isCompleted ? Date() : nil
        }

        todos[index].updatedAt = Date()
        save()
    }

    func setRecurringTodoActive(id: UUID, isActive: Bool) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].recurrenceRule?.isActive = isActive
        todos[index].updatedAt = Date()
        save()
    }

    func occurrences(on day: Date, includeCompleted: Bool = false) -> [TodoOccurrence] {
        todos.compactMap { RecurrenceService.occurrence(for: $0, on: day) }
            .filter { includeCompleted || !$0.isCompleted }
            .sorted(by: occurrenceSort)
    }

    func occurrences(from start: Date, to end: Date, includeCompleted: Bool = false) -> [TodoOccurrence] {
        todos.flatMap { RecurrenceService.occurrences(for: $0, from: start, to: end) }
            .filter { includeCompleted || !$0.isCompleted }
            .sorted(by: occurrenceSort)
    }

    func remainingCount(on day: Date) -> Int {
        occurrences(on: day).count
    }

    func completedOccurrences() -> [TodoOccurrence] {
        let completedSingleTodos = todos
            .filter { $0.recurrenceRule == nil && $0.isCompleted }
            .map {
                TodoOccurrence(
                    todo: $0,
                    occurrenceDate: $0.dueDate,
                    isCompleted: true,
                    completedAt: $0.completedAt
                )
            }

        let completedRecurringTodos = todos.flatMap { todo in
            todo.completedOccurrenceDates.map { completedDay in
                TodoOccurrence(
                    todo: todo,
                    occurrenceDate: CalendarService.mergingDay(completedDay, timeFrom: todo.dueDate),
                    isCompleted: true,
                    completedAt: completedDay
                )
            }
        }

        return (completedSingleTodos + completedRecurringTodos).sorted {
            ($0.completedAt ?? $0.occurrenceDate) > ($1.completedAt ?? $1.occurrenceDate)
        }
    }

    func addNote(title: String = "Untitled Note", body: String = "") -> UUID {
        let note = NoteItem(title: title, body: body)
        notes.insert(note, at: 0)
        save()
        return note.id
    }

    func updateNote(id: UUID, title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : title
        notes[index].body = body
        notes[index].updatedAt = Date()
        save()
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    private func occurrenceSort(_ lhs: TodoOccurrence, _ rhs: TodoOccurrence) -> Bool {
        if lhs.todo.priority != rhs.todo.priority {
            return priorityRank(lhs.todo.priority) > priorityRank(rhs.todo.priority)
        }
        return lhs.occurrenceDate < rhs.occurrenceDate
    }

    private func priorityRank(_ priority: TodoPriority) -> Int {
        switch priority {
        case .low: 0
        case .normal: 1
        case .high: 2
        }
    }

    private func load() {
        do {
            if let data = try PersistenceService.load() {
                todos = data.todos
                notes = data.notes
            } else {
                seedSampleData()
                save()
            }
        } catch {
            lastError = error.localizedDescription
            seedSampleData()
        }
    }

    private func save() {
        do {
            try PersistenceService.save(AppData(todos: todos, notes: notes))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func seedSampleData() {
        let now = Date()
        let calendar = CalendarService.calendar
        let todayAtTen = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let friday = calendar.date(byAdding: .day, value: 4, to: now) ?? now
        let mondayWednesdayFriday = [2, 4, 6]

        todos = [
            TodoItem(
                title: "Plan today",
                detail: "Review the week and pick the important three.",
                dueDate: todayAtTen,
                priority: .high
            ),
            TodoItem(
                title: "Daily reset",
                detail: "Clear desk, review inbox, and choose the next action.",
                dueDate: calendar.date(bySettingHour: 8, minute: 40, second: 0, of: now) ?? now,
                priority: .normal,
                recurrenceRule: RecurrenceRule(
                    type: .daily,
                    startDate: now
                )
            ),
            TodoItem(
                title: "Weekly review",
                detail: "Light recurring planning block.",
                dueDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now,
                priority: .normal,
                recurrenceRule: RecurrenceRule(
                    type: .weekly,
                    weekdays: mondayWednesdayFriday,
                    startDate: now
                )
            ),
            TodoItem(
                title: "Pay monthly card",
                detail: "Monthly finance check.",
                dueDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: friday) ?? friday,
                priority: .normal,
                recurrenceRule: RecurrenceRule(
                    type: .monthly,
                    dayOfMonth: 25,
                    startDate: now
                )
            ),
            TodoItem(
                title: "Draft next note",
                detail: "Capture loose ideas before they scatter.",
                dueDate: tomorrow,
                priority: .low
            )
        ]

        notes = [
            NoteItem(
                title: "Inbox",
                body: "Use this area for loose thoughts that are not Todo items yet."
            )
        ]
    }
}
