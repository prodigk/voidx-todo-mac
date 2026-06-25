import SwiftUI

struct TodoRow: View {
    let occurrence: TodoOccurrence
    var compact: Bool = false
    var showsEditButton: Bool = true
    var onToggle: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 3)
                .padding(.vertical, 2)

            Button(action: onToggle) {
                Image(systemName: occurrence.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 15 : 18, weight: .medium))
                    .foregroundStyle(occurrence.isCompleted ? CohereTheme.deepGreen : CohereTheme.slate)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(occurrence.isCompleted ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: compact ? 3 : 7) {
                HStack(spacing: 8) {
                    Text(occurrence.todo.title)
                        .font(.system(size: compact ? 13 : 15, weight: .medium))
                        .foregroundStyle(CohereTheme.ink)
                        .lineLimit(compact ? 1 : 2)
                        .strikethrough(occurrence.isCompleted)

                    if occurrence.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CohereTheme.deepGreen)
                            .help("Recurring")
                    }

                    PriorityDot(priority: occurrence.todo.priority)
                }

                if !compact && !occurrence.todo.detail.isEmpty {
                    Text(occurrence.todo.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(CohereTheme.slate)
                        .lineLimit(2)
                }

                Text(occurrence.occurrenceDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(CohereTheme.muted)
            }

            Spacer(minLength: 8)

            if !compact {
                if showsEditButton {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(CohereIconButtonStyle())
                    .help("Edit")
                }

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.coral))
                .help("Delete")
            }
        }
        .padding(compact ? 9 : 13)
        .background(compact ? CohereTheme.canvas.opacity(0.82) : CohereTheme.softStone.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }

    private var priorityColor: Color {
        switch occurrence.todo.priority {
        case .low: CohereTheme.muted
        case .normal: CohereTheme.actionBlue
        case .high: CohereTheme.coral
        }
    }
}

struct PriorityDot: View {
    let priority: TodoPriority

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .help(priority.label)
    }

    private var color: Color {
        switch priority {
        case .low: CohereTheme.muted
        case .normal: CohereTheme.actionBlue
        case .high: CohereTheme.coral
        }
    }
}
