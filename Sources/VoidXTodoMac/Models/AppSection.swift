import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case recurring
    case notes
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .week: "Week"
        case .month: "Month"
        case .recurring: "Routines"
        case .notes: "Notes"
        case .completed: "Completed"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .week: "calendar.day.timeline.left"
        case .month: "calendar"
        case .recurring: "repeat"
        case .notes: "note.text"
        case .completed: "checkmark.circle"
        }
    }
}
