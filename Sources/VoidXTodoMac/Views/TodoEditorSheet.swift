import SwiftUI

struct TodoEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TodoStore

    let todo: TodoItem?

    @State private var title: String
    @State private var detail: String
    @State private var dueDate: Date
    @State private var priority: TodoPriority

    init(todo: TodoItem?) {
        self.todo = todo
        _title = State(initialValue: todo?.title ?? "")
        _detail = State(initialValue: todo?.detail ?? "")
        _dueDate = State(initialValue: todo?.dueDate ?? Date())
        _priority = State(initialValue: todo?.priority ?? .normal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(todo == nil ? "New Todo" : "Edit Todo")
                .font(CohereTheme.displayFont(30))
                .foregroundStyle(CohereTheme.ink)

            TextField("Title", text: $title)
                .cohereField()

            TextField("Detail", text: $detail, axis: .vertical)
                .lineLimit(3...5)
                .cohereField()

            DatePicker("Due", selection: $dueDate)
                .font(.system(size: 13))
                .padding(12)
                .background(CohereTheme.softStone.opacity(0.58), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))

            Picker("Priority", selection: $priority) {
                ForEach(TodoPriority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(CohereTheme.bodyMuted)
                Button(todo == nil ? "Add" : "Save") { save() }
                    .buttonStyle(CoherePrimaryButtonStyle())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(CohereTheme.canvas)
    }

    private func save() {
        if var todo {
            todo.title = title
            todo.detail = detail
            todo.dueDate = dueDate
            todo.priority = priority
            store.updateTodo(todo)
        } else {
            store.addTodo(title: title, detail: detail, dueDate: dueDate, priority: priority)
        }
        dismiss()
    }
}
