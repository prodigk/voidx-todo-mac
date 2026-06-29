import SwiftUI

struct QuickAddTodoView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .normal
    @State private var categoryID: UUID?

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Add")
                        .font(CohereTheme.monoLabel())
                        .foregroundStyle(CohereTheme.deepGreen)
                    Text("Capture the task first. Fine tune only when needed.")
                        .font(.system(size: 12))
                        .foregroundStyle(CohereTheme.slate)
                }

                HStack(spacing: 12) {
                    TextField("Add a todo", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(CohereTheme.softStone.opacity(0.34), in: RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                                .stroke(CohereTheme.hairline, lineWidth: 1)
                        }
                        .onSubmit(add)

                    Button(action: add) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(CoherePrimaryButtonStyle())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack(spacing: 10) {
                    dueControl

                    Picker("", selection: $priority) {
                        ForEach(TodoPriority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                    .help("Priority")

                    CategoryMenuButton(selectedCategoryID: $categoryID)
                        .frame(width: 190)

                    Spacer()
                }
            }
        }
    }

    private var dueControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundStyle(CohereTheme.slate)
                .frame(width: 16)

            Text("Due")
                .font(CohereTheme.monoLabel(11))
                .foregroundStyle(CohereTheme.slate)

            Spacer(minLength: 4)

            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 250)
        .background(CohereTheme.controlSurface, in: Capsule())
        .overlay {
            Capsule().stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }

    private func add() {
        store.addTodo(title: title, detail: "", dueDate: dueDate, priority: priority, categoryID: categoryID)
        title = ""
        priority = .normal
    }
}
