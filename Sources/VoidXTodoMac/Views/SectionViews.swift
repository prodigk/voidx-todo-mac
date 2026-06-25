import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var editorTodo: TodoItem?
    @State private var isEditorPresented = false

    private var todayOccurrences: [TodoOccurrence] {
        store.occurrences(on: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    title: "Today",
                    subtitle: Date().formatted(date: .complete, time: .omitted),
                    count: todayOccurrences.count
                )

                QuickAddTodoView()

                QuietPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Focused List")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CohereTheme.ink)

                            Spacer()

                            Button {
                                editorTodo = nil
                                isEditorPresented = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(CohereIconButtonStyle())
                            .help("New Todo")
                        }

                        if todayOccurrences.isEmpty {
                            EmptyStateView(
                                title: "No todos for today",
                                subtitle: "Add the next small thing when it becomes clear."
                            )
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(todayOccurrences) { occurrence in
                                    TodoRow(
                                        occurrence: occurrence,
                                        onToggle: { store.toggleCompletion(occurrence) },
                                        onEdit: { edit(occurrence.todo) },
                                        onDelete: { store.deleteTodo(id: occurrence.todo.id) }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appSurface()
        .sheet(isPresented: $isEditorPresented) {
            TodoEditorSheet(todo: editorTodo)
                .environmentObject(store)
        }
    }

    private func edit(_ todo: TodoItem) {
        editorTodo = todo
        isEditorPresented = true
    }
}

struct WeekView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var focusedDate = Date()

    private var days: [Date] {
        CalendarService.daysInWeek(containing: focusedDate)
    }

    private var weekTitle: String {
        guard let first = days.first, let last = days.last else { return "" }
        return "\(first.formatted(date: .abbreviated, time: .omitted)) - \(last.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            CalendarHeader(
                title: "Week",
                subtitle: weekTitle,
                previousAction: { moveWeek(by: -1) },
                todayAction: { focusedDate = Date() },
                nextAction: { moveWeek(by: 1) }
            )

            HStack(spacing: 10) {
                ForEach(days, id: \.self) { day in
                    WeekDayColumn(day: day)
                }
            }
        }
        .appSurface()
    }

    private func moveWeek(by value: Int) {
        focusedDate = CalendarService.calendar.date(byAdding: .weekOfYear, value: value, to: focusedDate) ?? focusedDate
    }
}

struct MonthView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var focusedDate = Date()

    private var days: [Date] {
        CalendarService.monthGrid(containing: focusedDate)
    }

    private var monthTitle: String {
        focusedDate.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            CalendarHeader(
                title: "Month",
                subtitle: monthTitle,
                previousAction: { moveMonth(by: -1) },
                todayAction: { focusedDate = Date() },
                nextAction: { moveMonth(by: 1) }
            )

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(CalendarSymbols.weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(CohereTheme.slate)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        MonthDayCell(
                            day: day,
                            isInFocusedMonth: CalendarService.calendar.isDate(day, equalTo: focusedDate, toGranularity: .month)
                        )
                    }
                }
            }
        }
        .appSurface()
    }

    private func moveMonth(by value: Int) {
        focusedDate = CalendarService.calendar.date(byAdding: .month, value: value, to: focusedDate) ?? focusedDate
    }
}

struct RecurringView: View {
    @EnvironmentObject private var store: TodoStore

    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .normal
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var selectedWeekdays: Set<Int> = [CalendarService.calendar.component(.weekday, from: Date())]
    @State private var dayOfMonth = CalendarService.calendar.component(.day, from: Date())
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()

    private var recurringTodos: [TodoItem] {
        store.todos
            .filter { $0.recurrenceRule != nil }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    title: "Routines",
                    subtitle: "Daily, weekly, and monthly routines",
                    count: recurringTodos.filter { $0.recurrenceRule?.isActive == true }.count
                )

                HStack(alignment: .top, spacing: 14) {
                    recurringForm
                        .frame(minWidth: 360, maxWidth: 430)

                    recurringList
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .appSurface()
    }

    private var recurringForm: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("New Routine")
                    .font(.system(size: 15, weight: .medium))

                TextField("Title", text: $title)
                    .cohereField()

                TextField("Description", text: $detail, axis: .vertical)
                    .lineLimit(3...5)
                    .cohereField()

                DatePicker("Due time", selection: $dueDate, displayedComponents: [.hourAndMinute])
                    .padding(12)
                    .background(CohereTheme.softStone.opacity(0.58), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))

                Picker("Priority", selection: $priority) {
                    ForEach(TodoPriority.allCases) { priority in
                        Text(priority.label).tag(priority)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Repeat", selection: $recurrenceType) {
                    ForEach(RecurrenceType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                if recurrenceType == .weekly {
                    WeekdayPicker(selection: $selectedWeekdays)
                } else if recurrenceType == .monthly {
                    Stepper("Day \(dayOfMonth)", value: $dayOfMonth, in: 1...31)
                }

                DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                    .padding(12)
                    .background(CohereTheme.softStone.opacity(0.58), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))

                Toggle("Ends", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                        .padding(12)
                        .background(CohereTheme.softStone.opacity(0.58), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
                }

                Button {
                    addRecurringTodo()
                } label: {
                    Label("Add Routine", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CoherePrimaryButtonStyle())
                .disabled(!canAddRecurringTodo)
            }
        }
    }

    private var recurringList: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Routine Library")
                    .font(.system(size: 15, weight: .medium))

                if recurringTodos.isEmpty {
                    EmptyStateView(
                        title: "No routines yet",
                        subtitle: "Create a daily or weekly routine to keep it visible on schedule."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        RoutineGroup(title: "Daily Routine", todos: routines(of: .daily))
                        RoutineGroup(title: "Weekly Routine", todos: routines(of: .weekly))
                        RoutineGroup(title: "Monthly Routine", todos: routines(of: .monthly))
                    }
                }
            }
        }
    }

    private var canAddRecurringTodo: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasWeeklySelection = recurrenceType != .weekly || !selectedWeekdays.isEmpty
        return hasTitle && hasWeeklySelection
    }

    private func addRecurringTodo() {
        let clippedDay = CalendarService.clippedDayOfMonth(dayOfMonth, in: startDate)
        let rule = RecurrenceRule(
            type: recurrenceType,
            weekdays: recurrenceType == .weekly ? selectedWeekdays.sorted() : [],
            dayOfMonth: recurrenceType == .monthly ? clippedDay : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: true
        )
        let firstDueDate = CalendarService.mergingDay(startDate, timeFrom: dueDate)
        store.addTodo(title: title, detail: detail, dueDate: firstDueDate, priority: priority, recurrenceRule: rule)
        title = ""
        detail = ""
        priority = .normal
    }

    private func routines(of type: RecurrenceType) -> [TodoItem] {
        recurringTodos.filter { $0.recurrenceRule?.type == type }
    }
}

struct NotesView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var selectedNoteID: UUID?
    @State private var titleDraft = ""
    @State private var bodyDraft = ""

    private var selectedNote: NoteItem? {
        guard let selectedNoteID else { return store.notes.first }
        return store.notes.first { $0.id == selectedNoteID } ?? store.notes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(
                title: "Notes",
                subtitle: "Loose thoughts, separate from Todo",
                count: store.notes.count
            )

            HStack(spacing: 14) {
                QuietPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notebook")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Button {
                                let id = store.addNote()
                                selectNote(id)
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(CohereIconButtonStyle())
                            .help("New Note")
                        }

                        if store.notes.isEmpty {
                            EmptyStateView(title: "No notes", subtitle: "Start with one plain note.")
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(store.notes) { note in
                                        Button {
                                            saveCurrentDraft()
                                            selectNote(note.id)
                                        } label: {
                                            NoteListItem(note: note, isSelected: note.id == (selectedNote?.id))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(width: 280)

                QuietPanel {
                    noteEditor
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .appSurface()
        .onAppear {
            if selectedNoteID == nil, let first = store.notes.first {
                selectNote(first.id)
            }
        }
        .onDisappear {
            saveCurrentDraft()
        }
        .onChange(of: store.notes) { _, notes in
            if selectedNoteID == nil, let first = notes.first {
                selectNote(first.id)
            } else if let selectedNoteID, !notes.contains(where: { $0.id == selectedNoteID }) {
                selectNote(notes.first?.id)
            }
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let note = selectedNote {
                HStack {
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(CohereTheme.slate)

                    Spacer()

                    Button {
                        saveCurrentDraft()
                    } label: {
                        Image(systemName: "tray.and.arrow.down")
                    }
                    .buttonStyle(CohereIconButtonStyle())
                    .help("Save Note")

                    Button(role: .destructive) {
                        store.deleteNote(id: note.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.coral))
                    .help("Delete Note")
                }

                TextField("Title", text: $titleDraft)
                    .font(.system(size: 24, weight: .regular))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)

                Divider()

                TextEditor(text: $bodyDraft)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .background(CohereTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
            } else {
                EmptyStateView(title: "Select a note", subtitle: "Create or choose a note from the notebook.")
            }
        }
    }

    private func selectNote(_ id: UUID?) {
        selectedNoteID = id
        guard let id, let note = store.notes.first(where: { $0.id == id }) else {
            titleDraft = ""
            bodyDraft = ""
            return
        }
        titleDraft = note.title
        bodyDraft = note.body
    }

    private func saveCurrentDraft() {
        guard let note = selectedNote else { return }
        store.updateNote(id: note.id, title: titleDraft, body: bodyDraft)
    }
}

struct CompletedView: View {
    @EnvironmentObject private var store: TodoStore

    private var completed: [TodoOccurrence] {
        store.completedOccurrences()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    title: "Completed",
                    subtitle: "Recently finished work",
                    count: completed.count
                )

                QuietPanel {
                    if completed.isEmpty {
                        EmptyStateView(title: "Nothing completed yet", subtitle: "Completed todos will collect here.")
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(completed) { occurrence in
                                TodoRow(
                                    occurrence: occurrence,
                                    showsEditButton: false,
                                    onToggle: { store.toggleCompletion(occurrence) },
                                    onEdit: { },
                                    onDelete: { store.deleteTodo(id: occurrence.todo.id) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .appSurface()
    }
}

private struct CalendarHeader: View {
    let title: String
    let subtitle: String
    let previousAction: () -> Void
    let todayAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(CohereTheme.ink)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(CohereTheme.slate)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: previousAction) {
                    Image(systemName: "chevron.left")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(CohereIconButtonStyle())
                .help("Previous")

                Button("Today", action: todayAction)
                    .buttonStyle(CoherePrimaryButtonStyle())

                Button(action: nextAction) {
                    Image(systemName: "chevron.right")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(CohereIconButtonStyle())
                .help("Next")
            }
        }
        .padding(.bottom, 10)
    }
}

private struct WeekDayColumn: View {
    @EnvironmentObject private var store: TodoStore
    let day: Date

    private var occurrences: [TodoOccurrence] {
        store.occurrences(on: day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(CohereTheme.slate)
                    Text(day.formatted(.dateTime.day()))
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(CohereTheme.ink)
                }

                Spacer()

                CountChip(count: occurrences.count)
            }

            if occurrences.isEmpty {
                Text("Clear")
                    .font(.system(size: 12))
                    .foregroundStyle(CohereTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            } else {
                ForEach(occurrences.prefix(4)) { occurrence in
                    TodoRow(
                        occurrence: occurrence,
                        compact: true,
                        onToggle: { store.toggleCompletion(occurrence) },
                        onEdit: { },
                        onDelete: { store.deleteTodo(id: occurrence.todo.id) }
                    )
                }

                if occurrences.count > 4 {
                    Text("+\(occurrences.count - 4) more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CohereTheme.deepGreen)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CalendarService.isSameDay(day, Date()) ? CohereTheme.paleGreen : CohereTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(CohereTheme.borderLight, lineWidth: 1)
        }
    }
}

private struct MonthDayCell: View {
    @EnvironmentObject private var store: TodoStore
    let day: Date
    let isInFocusedMonth: Bool

    private var occurrences: [TodoOccurrence] {
        store.occurrences(on: day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 13, weight: CalendarService.isSameDay(day, Date()) ? .bold : .medium))
                    .foregroundStyle(isInFocusedMonth ? CohereTheme.ink : CohereTheme.muted)
                Spacer()
                if !occurrences.isEmpty {
                    CountChip(count: occurrences.count)
                }
            }

            ForEach(occurrences.prefix(3)) { occurrence in
                HStack(spacing: 5) {
                    PriorityDot(priority: occurrence.todo.priority)
                    Text(occurrence.todo.title)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isInFocusedMonth ? CohereTheme.ink : CohereTheme.slate)
                        .lineLimit(1)
                    if occurrence.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CohereTheme.deepGreen)
                    }
                }
            }

            if occurrences.count > 3 {
                Text("+\(occurrences.count - 3) more")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CohereTheme.deepGreen)
            }

            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(minHeight: 98, maxHeight: .infinity, alignment: .topLeading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(CohereTheme.borderLight, lineWidth: 1)
        }
    }

    private var background: Color {
        if CalendarService.isSameDay(day, Date()) {
            return CohereTheme.paleGreen
        }
        return isInFocusedMonth ? CohereTheme.canvas : CohereTheme.softStone.opacity(0.45)
    }
}

private struct RecurringTodoRow: View {
    @EnvironmentObject private var store: TodoStore
    let todo: TodoItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: routineIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CohereTheme.deepGreen)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(todo.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CohereTheme.ink)
                    PriorityDot(priority: todo.priority)
                }

                if !todo.detail.isEmpty {
                    Text(todo.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(CohereTheme.slate)
                        .lineLimit(2)
                }

                Text(ruleText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(CohereTheme.muted)
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: { todo.recurrenceRule?.isActive == true },
                    set: { store.setRecurringTodoActive(id: todo.id, isActive: $0) }
                )
            )
            .labelsHidden()
            .help("Toggle active")

            Button(role: .destructive) {
                store.deleteTodo(id: todo.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.coral))
            .help("Delete")
        }
        .padding(12)
        .background(CohereTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(CohereTheme.borderLight, lineWidth: 1)
        }
    }

    private var ruleText: String {
        guard let rule = todo.recurrenceRule else { return "Not recurring" }
        switch rule.type {
        case .daily:
            return "Daily"
        case .weekly:
            let labels = rule.weekdays
                .compactMap { CalendarSymbols.shortWeekdayName(for: $0) }
                .joined(separator: ", ")
            return "Weekly: \(labels)"
        case .monthly:
            return "Monthly: day \(rule.dayOfMonth ?? 1)"
        }
    }

    private var routineIcon: String {
        guard let rule = todo.recurrenceRule else { return "repeat" }
        switch rule.type {
        case .daily:
            return "sun.max"
        case .weekly:
            return "calendar.day.timeline.left"
        case .monthly:
            return "calendar"
        }
    }
}

private struct RoutineGroup: View {
    let title: String
    let todos: [TodoItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(CohereTheme.slate)
                CountChip(count: todos.count)
            }

            if todos.isEmpty {
                Text("None")
                    .font(.system(size: 12))
                    .foregroundStyle(CohereTheme.muted)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(todos) { todo in
                        RecurringTodoRow(todo: todo)
                    }
                }
            }
        }
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CalendarSymbols.weekdayOptions, id: \.value) { option in
                Button {
                    toggle(option.value)
                } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection.contains(option.value) ? CohereTheme.canvas : CohereTheme.ink)
                .background(selection.contains(option.value) ? CohereTheme.primary : CohereTheme.softStone)
                .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
                .help(option.fullLabel)
            }
        }
    }

    private func toggle(_ value: Int) {
        if selection.contains(value) {
            selection.remove(value)
        } else {
            selection.insert(value)
        }
    }
}

private struct NoteListItem: View {
    let note: NoteItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(note.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CohereTheme.ink)
                .lineLimit(1)
            Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(CohereTheme.slate)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? CohereTheme.paleBlue : CohereTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(isSelected ? CohereTheme.actionBlue.opacity(0.45) : CohereTheme.borderLight, lineWidth: 1)
        }
    }
}

private struct CountChip: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(count == 0 ? CohereTheme.slate : CohereTheme.deepGreen)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(count == 0 ? CohereTheme.softStone : CohereTheme.paleGreen, in: Capsule())
    }
}

private struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CohereTheme.ink)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(CohereTheme.slate)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .center)
    }
}

private enum CalendarSymbols {
    static let weekdayOptions: [(value: Int, label: String, fullLabel: String)] = [
        (2, "M", "Monday"),
        (3, "T", "Tuesday"),
        (4, "W", "Wednesday"),
        (5, "T", "Thursday"),
        (6, "F", "Friday"),
        (7, "S", "Saturday"),
        (1, "S", "Sunday")
    ]

    static let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    static func shortWeekdayName(for value: Int) -> String? {
        weekdayOptions.first { $0.value == value }?.fullLabel
    }
}
