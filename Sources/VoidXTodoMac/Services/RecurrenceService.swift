import Foundation

enum RecurrenceService {
    static func occurrence(for todo: TodoItem, on day: Date) -> TodoOccurrence? {
        guard todo.scheduleScope == .day else { return nil }

        if let rule = todo.recurrenceRule {
            guard matches(rule: rule, on: day) else { return nil }
            let occurrenceDate = CalendarService.mergingDay(day, timeFrom: todo.dueDate)
            return TodoOccurrence(
                todo: todo,
                occurrenceDate: occurrenceDate,
                isCompleted: isCompleted(todo: todo, on: day),
                completedAt: completionDate(todo: todo, on: day)
            )
        }

        guard CalendarService.isSameDay(todo.dueDate, day) else { return nil }
        return TodoOccurrence(
            todo: todo,
            occurrenceDate: todo.dueDate,
            isCompleted: todo.isCompleted,
            completedAt: todo.completedAt
        )
    }

    static func occurrences(for todo: TodoItem, from start: Date, to end: Date) -> [TodoOccurrence] {
        var result: [TodoOccurrence] = []
        var day = CalendarService.startOfDay(start)
        let lastDay = CalendarService.startOfDay(end)

        while day < lastDay {
            if let occurrence = occurrence(for: todo, on: day) {
                result.append(occurrence)
            }
            guard let nextDay = CalendarService.calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = nextDay
        }

        return result
    }

    static func isCompleted(todo: TodoItem, on day: Date) -> Bool {
        let normalizedDay = CalendarService.startOfDay(day)
        return todo.completedOccurrenceDates.contains { CalendarService.isSameDay($0, normalizedDay) }
    }

    private static func completionDate(todo: TodoItem, on day: Date) -> Date? {
        todo.completedOccurrenceDates.first { CalendarService.isSameDay($0, day) }
    }

    private static func matches(rule: RecurrenceRule, on day: Date) -> Bool {
        guard rule.isActive else { return false }
        let normalizedDay = CalendarService.startOfDay(day)
        let start = CalendarService.startOfDay(rule.startDate)
        guard normalizedDay >= start else { return false }
        if let endDate = rule.endDate, normalizedDay > CalendarService.startOfDay(endDate) {
            return false
        }

        switch rule.type {
        case .daily:
            return true
        case .weekly:
            let weekday = CalendarService.calendar.component(.weekday, from: normalizedDay)
            return rule.weekdays.contains(weekday)
        case .monthly:
            let dayOfMonth = CalendarService.calendar.component(.day, from: normalizedDay)
            return dayOfMonth == rule.dayOfMonth
        }
    }
}
