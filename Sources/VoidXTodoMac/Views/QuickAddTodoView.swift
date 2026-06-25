import SwiftUI

struct QuickAddTodoView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .normal

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Add")
                    .font(CohereTheme.monoLabel())
                    .foregroundStyle(CohereTheme.deepGreen)

                HStack(spacing: 10) {
                    TextField("Add a todo", text: $title)
                        .cohereField()
                        .onSubmit(add)

                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(width: 190)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(CohereTheme.softStone.opacity(0.7), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))

                    Picker("", selection: $priority) {
                        ForEach(TodoPriority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 210)

                    Button(action: add) {
                        Image(systemName: "plus")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.canvas, background: CohereTheme.primary))
                    .help("Add Todo")
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func add() {
        store.addTodo(title: title, detail: "", dueDate: dueDate, priority: priority)
        title = ""
        priority = .normal
    }
}
