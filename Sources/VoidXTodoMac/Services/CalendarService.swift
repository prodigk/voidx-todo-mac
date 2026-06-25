import Foundation

enum CalendarService {
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

    static func startOfWeek(containing date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? startOfDay(date)
    }

    static func daysInWeek(containing date: Date) -> [Date] {
        let start = startOfWeek(containing: date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func startOfMonth(containing date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(date)
    }

    static func monthGrid(containing date: Date) -> [Date] {
        let monthStart = startOfMonth(containing: date)
        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    static func dateIntervalForWeek(containing date: Date) -> DateInterval {
        let start = startOfWeek(containing: date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    static func dateIntervalForMonth(containing date: Date) -> DateInterval {
        let start = startOfMonth(containing: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    static func clippedDayOfMonth(_ day: Int, in date: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            return min(max(day, 1), 31)
        }
        return min(max(day, range.lowerBound), range.upperBound - 1)
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
