import SwiftUI

struct TodoEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TodoStore

    let todo: TodoItem?

    @State private var title: String
    @State private var detail: String
    @State private var dueDate: Date
    @State private var priority: TodoPriority
    @State private var categoryID: UUID?
    @State private var scheduleScope: TodoScheduleScope

    init(todo: TodoItem?, defaultDueDate: Date = Date(), defaultScheduleScope: TodoScheduleScope = .day) {
        self.todo = todo
        _title = State(initialValue: todo?.title ?? "")
        _detail = State(initialValue: todo?.detail ?? "")
        _dueDate = State(initialValue: todo?.dueDate ?? defaultDueDate)
        _priority = State(initialValue: todo?.priority ?? .normal)
        _categoryID = State(initialValue: todo?.categoryID)
        _scheduleScope = State(initialValue: todo?.scheduleScope ?? defaultScheduleScope)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(CohereTheme.monoLabel(11))
                    .foregroundStyle(CohereTheme.slate)

                Picker("Type", selection: $scheduleScope) {
                    ForEach(TodoScheduleScope.allCases) { scope in
                        Text(scope.label).tag(scope)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            duePicker

            Picker("Priority", selection: $priority) {
                ForEach(TodoPriority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(CohereTheme.monoLabel(11))
                    .foregroundStyle(CohereTheme.slate)
                CategorySelectionControl(selectedCategoryID: $categoryID)
            }

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
        .background(CohereTheme.panelSurface)
    }

    private var duePicker: some View {
        DatePicker(
            scheduleScope == .day ? "Due" : "Week",
            selection: $dueDate,
            displayedComponents: scheduleScope == .day ? [.date, .hourAndMinute] : [.date]
        )
        .font(.system(size: 13))
        .padding(12)
        .background(CohereTheme.controlSurface, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }

    private func save() {
        if var todo {
            todo.title = title
            todo.detail = detail
            todo.dueDate = dueDate
            todo.priority = priority
            todo.categoryID = categoryID
            todo.scheduleScope = scheduleScope
            store.updateTodo(todo)
        } else {
            store.addTodo(title: title, detail: detail, dueDate: dueDate, priority: priority, categoryID: categoryID, scheduleScope: scheduleScope)
        }
        dismiss()
    }
}
