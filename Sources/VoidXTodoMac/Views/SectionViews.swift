import SwiftUI
import UniformTypeIdentifiers

struct TodayView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var editorTodo: TodoItem?
    @State private var isEditorPresented = false

    private var todayOccurrences: [TodoOccurrence] {
        store.occurrences(on: Date(), includeCompleted: true)
    }

    private var todayRemainingCount: Int {
        todayOccurrences.filter { !$0.isCompleted }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    title: "Today",
                    subtitle: Date().formatted(date: .complete, time: .omitted),
                    count: todayRemainingCount
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
    @State private var editorTodo: TodoItem?
    @State private var editorDueDate = Date()
    @State private var editorScheduleScope: TodoScheduleScope = .day
    @State private var isEditorPresented = false

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

            GeometryReader { proxy in
                VStack(spacing: 14) {
                    WeekCalendarGrid(days: days, onAddTodo: addTodo)
                        .frame(height: max(220, proxy.size.height * 0.56))

                    WeeklyTaskLane(
                        weekStart: CalendarService.startOfWeek(containing: focusedDate),
                        onAddTodo: addWeeklyTodo,
                        onEditTodo: editTodo
                    )
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appSurface()
        .sheet(isPresented: $isEditorPresented) {
            TodoEditorSheet(todo: editorTodo, defaultDueDate: editorDueDate, defaultScheduleScope: editorScheduleScope)
                .environmentObject(store)
        }
    }

    private func moveWeek(by value: Int) {
        focusedDate = CalendarService.calendar.date(byAdding: .weekOfYear, value: value, to: focusedDate) ?? focusedDate
    }

    private func addTodo(on day: Date) {
        editorTodo = nil
        editorDueDate = CalendarService.mergingDay(day, timeFrom: Date())
        editorScheduleScope = .day
        isEditorPresented = true
    }

    private func addWeeklyTodo() {
        editorTodo = nil
        editorDueDate = CalendarService.startOfWeek(containing: focusedDate)
        editorScheduleScope = .week
        isEditorPresented = true
    }

    private func editTodo(_ todo: TodoItem) {
        editorTodo = todo
        editorDueDate = todo.dueDate
        editorScheduleScope = todo.scheduleScope
        isEditorPresented = true
    }
}

struct MonthView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var focusedDate = Date()
    @State private var editorTodo: TodoItem?
    @State private var editorDueDate = Date()
    @State private var isEditorPresented = false

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

            MonthCalendarGrid(days: days, focusedDate: focusedDate, onAddTodo: addTodo)
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appSurface()
        .sheet(isPresented: $isEditorPresented) {
            TodoEditorSheet(todo: editorTodo, defaultDueDate: editorDueDate)
                .environmentObject(store)
        }
    }

    private func moveMonth(by value: Int) {
        focusedDate = CalendarService.calendar.date(byAdding: .month, value: value, to: focusedDate) ?? focusedDate
    }

    private func addTodo(on day: Date) {
        editorTodo = nil
        editorDueDate = CalendarService.mergingDay(day, timeFrom: Date())
        isEditorPresented = true
    }
}

struct RecurringView: View {
    @EnvironmentObject private var store: TodoStore

    @State private var editingTodoID: UUID?
    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .normal
    @State private var categoryID: UUID?
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
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditingRoutine ? "Edit Routine" : "New Routine")
                        .font(CohereTheme.monoLabel())
                        .foregroundStyle(CohereTheme.deepGreen)
                    Text(formSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(CohereTheme.slate)
                }

                HStack(spacing: 12) {
                    TextField("Routine title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(CohereTheme.softStone.opacity(0.34), in: RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                                .stroke(CohereTheme.hairline, lineWidth: 1)
                        }
                        .onSubmit(saveRecurringTodo)

                    Button {
                        saveRecurringTodo()
                    } label: {
                        Label(primaryFormActionTitle, systemImage: primaryFormActionIcon)
                    }
                    .buttonStyle(CoherePrimaryButtonStyle())
                    .disabled(!canSaveRecurringTodo)

                    if isEditingRoutine {
                        Button {
                            resetRecurringForm()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(CohereIconButtonStyle())
                        .help("Cancel edit")
                    }
                }

                TextField("Optional description", text: $detail, axis: .vertical)
                    .lineLimit(2...3)
                    .cohereField()

                VStack(alignment: .leading, spacing: 10) {
                    Picker("", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if recurrenceType == .weekly {
                        WeekdayPicker(selection: $selectedWeekdays)
                    } else if recurrenceType == .monthly {
                        routinePill(systemImage: "calendar.badge.clock", label: "Monthly") {
                            Stepper("Day \(dayOfMonth)", value: $dayOfMonth, in: 1...31)
                                .labelsHidden()
                        }
                    }
                }

                HStack(spacing: 10) {
                    routinePill(systemImage: "clock", label: "Time") {
                        DatePicker("", selection: $dueDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    CategoryMenuButton(selectedCategoryID: $categoryID)
                        .frame(maxWidth: .infinity)
                }

                HStack(spacing: 10) {
                    routinePill(systemImage: "flag", label: "Priority") {
                        Picker("", selection: $priority) {
                            ForEach(TodoPriority.allCases) { priority in
                                Text(priority.label).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        routinePill(systemImage: "play", label: "Starts") {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Toggle("Ends", isOn: $hasEndDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CohereTheme.bodyMuted)
                    }

                    if hasEndDate {
                        routinePill(systemImage: "stop", label: "Ends") {
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
    }

    private func routinePill<Content: View>(
        systemImage: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(CohereTheme.slate)
                .frame(width: 16)

            Text(label)
                .font(CohereTheme.monoLabel(11))
                .foregroundStyle(CohereTheme.slate)

            Spacer(minLength: 4)

            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(CohereTheme.controlSurface, in: Capsule())
        .overlay {
            Capsule().stroke(CohereTheme.hairline, lineWidth: 1)
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
                        RoutineGroup(title: "Daily Routine", todos: routines(of: .daily), onEdit: beginEditing)
                        RoutineGroup(title: "Weekly Routine", todos: routines(of: .weekly), onEdit: beginEditing)
                        RoutineGroup(title: "Monthly Routine", todos: routines(of: .monthly), onEdit: beginEditing)
                    }
                }
            }
        }
    }

    private var isEditingRoutine: Bool {
        editingTodoID != nil
    }

    private var formSubtitle: String {
        isEditingRoutine ? "Update the routine details and schedule." : "Name the routine first, then tune the schedule."
    }

    private var primaryFormActionTitle: String {
        isEditingRoutine ? "Save" : "Add"
    }

    private var primaryFormActionIcon: String {
        isEditingRoutine ? "checkmark" : "plus"
    }

    private var canSaveRecurringTodo: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasWeeklySelection = recurrenceType != .weekly || !selectedWeekdays.isEmpty
        return hasTitle && hasWeeklySelection
    }

    private func saveRecurringTodo() {
        guard canSaveRecurringTodo else { return }
        let clippedDay = CalendarService.clippedDayOfMonth(dayOfMonth, in: startDate)
        let existingTodo = editingTodoID.flatMap { id in store.todos.first { $0.id == id } }
        let existingRule = existingTodo?.recurrenceRule
        let rule = RecurrenceRule(
            id: existingRule?.id ?? UUID(),
            type: recurrenceType,
            weekdays: recurrenceType == .weekly ? selectedWeekdays.sorted() : [],
            dayOfMonth: recurrenceType == .monthly ? clippedDay : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: existingRule?.isActive ?? true
        )
        let firstDueDate = CalendarService.mergingDay(startDate, timeFrom: dueDate)

        if var existingTodo {
            existingTodo.title = title
            existingTodo.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            existingTodo.dueDate = firstDueDate
            existingTodo.priority = priority
            existingTodo.categoryID = categoryID
            existingTodo.recurrenceRule = rule
            store.updateTodo(existingTodo)
        } else {
            store.addTodo(title: title, detail: detail, dueDate: firstDueDate, priority: priority, categoryID: categoryID, recurrenceRule: rule)
        }

        resetRecurringForm()
    }

    private func beginEditing(_ todo: TodoItem) {
        guard let rule = todo.recurrenceRule else { return }
        editingTodoID = todo.id
        title = todo.title
        detail = todo.detail
        dueDate = todo.dueDate
        priority = todo.priority
        categoryID = todo.categoryID
        recurrenceType = rule.type
        selectedWeekdays = Set(rule.weekdays.isEmpty ? [CalendarService.calendar.component(.weekday, from: rule.startDate)] : rule.weekdays)
        dayOfMonth = rule.dayOfMonth ?? CalendarService.calendar.component(.day, from: rule.startDate)
        startDate = rule.startDate
        hasEndDate = rule.endDate != nil
        endDate = rule.endDate ?? Date()
    }

    private func resetRecurringForm() {
        editingTodoID = nil
        title = ""
        detail = ""
        dueDate = Date()
        priority = .normal
        categoryID = nil
        recurrenceType = .daily
        selectedWeekdays = [CalendarService.calendar.component(.weekday, from: Date())]
        dayOfMonth = CalendarService.calendar.component(.day, from: Date())
        startDate = Date()
        hasEndDate = false
        endDate = Date()
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
    @State private var noteCategoryID: UUID?
    @State private var editorMode: NoteEditorMode = .write

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
                HStack(spacing: 10) {
                    CategoryMenuButton(selectedCategoryID: $noteCategoryID)
                        .frame(width: 190)

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
                    .textFieldStyle(.plain)
                    .font(.system(size: 28, weight: .regular))
                    .lineLimit(1)
                    .frame(minHeight: 48, alignment: .center)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                Divider()

                VStack(spacing: 10) {
                    HStack {
                        Text("Markdown")
                            .font(CohereTheme.monoLabel(11))
                            .foregroundStyle(CohereTheme.slate)

                        Spacer()

                        Picker("", selection: $editorMode) {
                            ForEach(NoteEditorMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 180)
                    }

                    if editorMode == .write {
                        TextEditor(text: $bodyDraft)
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                            .background(CohereTheme.controlSurface)
                            .clipShape(RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
                    } else {
                        MarkdownPreview(markdown: bodyDraft)
                    }
                }
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
            noteCategoryID = nil
            return
        }
        titleDraft = note.title
        bodyDraft = note.body
        noteCategoryID = note.categoryID
    }

    private func saveCurrentDraft() {
        guard let note = selectedNote else { return }
        store.updateNote(id: note.id, title: titleDraft, body: bodyDraft, categoryID: noteCategoryID)
    }
}

private enum NoteEditorMode: String, CaseIterable, Identifiable {
    case write
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .write:
            return "Write"
        case .preview:
            return "Preview"
        }
    }
}

struct CompletedView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var focusedMonth = Date()

    private var monthInterval: DateInterval {
        CalendarService.dateIntervalForMonth(containing: focusedMonth)
    }

    private var completed: [TodoOccurrence] {
        store.completedOccurrences(in: monthInterval)
    }

    private var monthTitle: String {
        focusedMonth.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CompletedMonthHeader(
                    title: "Completed",
                    subtitle: monthTitle,
                    count: completed.count,
                    previousAction: { moveMonth(by: -1) },
                    currentMonthAction: { focusedMonth = Date() },
                    nextAction: { moveMonth(by: 1) }
                )

                if !completed.isEmpty {
                    CompletedCategoryAnalytics(completed: completed, dateInterval: monthInterval)
                }

                QuietPanel {
                    if completed.isEmpty {
                        EmptyStateView(title: "Nothing completed this month", subtitle: "Finished todos for \(monthTitle) will collect here.")
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

    private func moveMonth(by value: Int) {
        focusedMonth = CalendarService.calendar.date(byAdding: .month, value: value, to: focusedMonth) ?? focusedMonth
    }
}

private struct CompletedMonthHeader: View {
    let title: String
    let subtitle: String
    let count: Int
    let previousAction: () -> Void
    let currentMonthAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("VOIDX TODO")
                    .font(CohereTheme.monoLabel(11))
                    .foregroundStyle(CohereTheme.deepGreen)
                Text(title)
                    .font(CohereTheme.displayFont(44))
                    .foregroundStyle(CohereTheme.ink)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(CohereTheme.slate)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(count) done")
                    .font(CohereTheme.monoLabel(12))
                    .foregroundStyle(CohereTheme.onPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(CohereTheme.primary, in: Capsule())

                Button(action: previousAction) {
                    Image(systemName: "chevron.left")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(CohereIconButtonStyle())
                .help("Previous month")

                Button("This Month", action: currentMonthAction)
                    .buttonStyle(CoherePrimaryButtonStyle())

                Button(action: nextAction) {
                    Image(systemName: "chevron.right")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(CohereIconButtonStyle())
                .help("Next month")
            }
        }
        .padding(.bottom, 14)
    }
}

private struct CompletedCategoryAnalytics: View {
    @EnvironmentObject private var store: TodoStore

    let completed: [TodoOccurrence]
    let dateInterval: DateInterval

    private var weekStarts: [Date] {
        var starts: [Date] = []
        var cursor = CalendarService.startOfWeek(containing: dateInterval.start)

        while cursor < dateInterval.end {
            starts.append(cursor)
            guard let next = CalendarService.calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }

        return starts
    }

    private var insights: [CompletedCategoryInsight] {
        var grouped: [String: [TodoOccurrence]] = [:]

        for occurrence in completed {
            let key = occurrence.todo.categoryID?.uuidString ?? CompletedCategoryInsight.uncategorizedID
            grouped[key, default: []].append(occurrence)
        }

        return grouped.map { key, occurrences in
            let categoryID = occurrences.first?.todo.categoryID
            let category = categoryID.flatMap { store.category(for: $0) }
            let latestDate = occurrences.map(completionDate).max() ?? Date()
            let weeklyCounts = weekStarts.map { weekStart in
                let weekEnd = CalendarService.calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                return occurrences.filter {
                    let date = completionDate(for: $0)
                    return date >= weekStart && date < weekEnd
                }.count
            }

            return CompletedCategoryInsight(
                id: key,
                title: category?.name ?? (categoryID == nil ? "No category" : "Archived tag"),
                category: category,
                count: occurrences.count,
                latestDate: latestDate,
                weeklyCounts: weeklyCounts
            )
        }
        .sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private var maxWeeklyCount: Int {
        max(insights.flatMap(\.weeklyCounts).max() ?? 0, 1)
    }

    private var totalCount: Int {
        completed.count
    }

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion by Tag")
                            .font(CohereTheme.monoLabel())
                            .foregroundStyle(CohereTheme.deepGreen)
                        Text("Which areas are getting finished over time")
                            .font(.system(size: 12))
                            .foregroundStyle(CohereTheme.slate)
                    }

                    Spacer()

                    Text("\(totalCount) done")
                        .font(CohereTheme.monoLabel(12))
                        .foregroundStyle(CohereTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CohereTheme.softStone.opacity(0.56), in: Capsule())
                }

                CompletedCategoryStackedBar(insights: insights, totalCount: totalCount)
                    .frame(height: 16)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Tag")
                            .font(CohereTheme.monoLabel(10))
                            .foregroundStyle(CohereTheme.slate)
                        Spacer()
                        Text("Weeks in month")
                            .font(CohereTheme.monoLabel(10))
                            .foregroundStyle(CohereTheme.slate)
                            .frame(width: 88, alignment: .trailing)
                    }

                    ForEach(insights) { insight in
                        CompletedCategoryInsightRow(
                            insight: insight,
                            totalCount: totalCount,
                            maxWeeklyCount: maxWeeklyCount
                        )
                    }
                }
            }
        }
    }

    private func completionDate(for occurrence: TodoOccurrence) -> Date {
        occurrence.completedAt ?? occurrence.occurrenceDate
    }
}

private struct CompletedCategoryInsight: Identifiable {
    static let uncategorizedID = "uncategorized"

    let id: String
    let title: String
    let category: TodoCategory?
    let count: Int
    let latestDate: Date
    let weeklyCounts: [Int]
}

private struct CompletedCategoryStackedBar: View {
    let insights: [CompletedCategoryInsight]
    let totalCount: Int

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(insights) { insight in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(for: insight))
                        .frame(width: max(4, proxy.size.width * CGFloat(insight.count) / CGFloat(max(totalCount, 1))))
                        .help("\(insight.title): \(insight.count)")
                }
            }
        }
        .background(CohereTheme.softStone.opacity(0.42), in: RoundedRectangle(cornerRadius: 5))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func color(for insight: CompletedCategoryInsight) -> Color {
        insight.category.map { CategoryVisuals.base(for: $0) } ?? CohereTheme.slate
    }
}

private struct CompletedCategoryInsightRow: View {
    let insight: CompletedCategoryInsight
    let totalCount: Int
    let maxWeeklyCount: Int

    private var ratio: CGFloat {
        CGFloat(insight.count) / CGFloat(max(totalCount, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                tagLabel

                Spacer(minLength: 10)

                Text("\(insight.count)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CohereTheme.ink)
                    .frame(width: 34, alignment: .trailing)

                Text("\(Int((ratio * 100).rounded()))%")
                    .font(CohereTheme.monoLabel(10))
                    .foregroundStyle(CohereTheme.slate)
                    .frame(width: 38, alignment: .trailing)

                weeklyTrend
                    .frame(width: 88, height: 30, alignment: .trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CohereTheme.softStone.opacity(0.56))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(baseColor)
                        .frame(width: max(6, proxy.size.width * ratio))
                }
            }
            .frame(height: 8)
        }
        .padding(10)
        .background(fillColor.opacity(0.74), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                .stroke(baseColor.opacity(0.18), lineWidth: 1)
        }
    }

    private var tagLabel: some View {
        HStack(spacing: 7) {
            if let category = insight.category {
                CategoryPatternSwatch(category: category, size: 14)
            } else {
                Image(systemName: "tag.slash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CohereTheme.slate)
                    .frame(width: 14)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)

                Text("Last \(insight.latestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(CohereTheme.monoLabel(9))
                    .foregroundStyle(CohereTheme.slate)
            }
        }
    }

    private var weeklyTrend: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(insight.weeklyCounts.enumerated()), id: \.offset) { _, count in
                RoundedRectangle(cornerRadius: 2)
                    .fill(count == 0 ? CohereTheme.hairline.opacity(0.7) : baseColor)
                    .frame(
                        width: 8,
                        height: count == 0 ? 3 : max(5, CGFloat(count) / CGFloat(maxWeeklyCount) * 28)
                    )
                    .help("\(count) completed")
            }
        }
    }

    private var baseColor: Color {
        insight.category.map { CategoryVisuals.base(for: $0) } ?? CohereTheme.slate
    }

    private var fillColor: Color {
        insight.category.map { CategoryVisuals.fill(for: $0) } ?? CohereTheme.softStone
    }

    private var foregroundColor: Color {
        insight.category.map { CategoryVisuals.foreground(for: $0) } ?? CohereTheme.ink
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

private struct WeekCalendarGrid: View {
    let days: [Date]
    let onAddTodo: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                WeekDayColumn(day: day, index: index, onAddTodo: onAddTodo)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CohereTheme.panelSurface)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }
}

private struct WeeklyTaskLane: View {
    @EnvironmentObject private var store: TodoStore

    let weekStart: Date
    let onAddTodo: () -> Void
    let onEditTodo: (TodoItem) -> Void

    private var weekTasks: [TodoOccurrence] {
        store.weeklyTodos(in: weekStart, includeCompleted: true)
    }

    private var remainingCount: Int {
        weekTasks.filter { !$0.isCompleted }.count
    }

    private var weekRangeText: String {
        let weekEnd = CalendarService.calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(weekStart.formatted(date: .abbreviated, time: .omitted)) - \(weekEnd.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        QuietPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Week Tasks")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CohereTheme.ink)

                            Text("\(remainingCount)")
                                .font(CohereTheme.monoLabel(10))
                                .foregroundStyle(CohereTheme.deepGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(CohereTheme.paleGreen, in: Capsule())
                        }

                        Text(weekRangeText)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(CohereTheme.slate)
                    }

                    Spacer()

                    Button(action: onAddTodo) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(CoherePrimaryButtonStyle())
                    .help("New week task")
                }

                if weekTasks.isEmpty {
                    EmptyStateView(
                        title: "No week tasks",
                        subtitle: "Capture work that only needs to land sometime this week."
                    )
                    .frame(maxWidth: .infinity, minHeight: 86)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(weekTasks) { occurrence in
                                WeeklyTaskRow(
                                    occurrence: occurrence,
                                    onToggle: { store.toggleCompletion(occurrence) },
                                    onEdit: { onEditTodo(occurrence.todo) },
                                    onDelete: { store.deleteTodo(id: occurrence.todo.id) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct WeeklyTaskRow: View {
    @EnvironmentObject private var store: TodoStore

    let occurrence: TodoOccurrence
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: occurrence.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(occurrence.isCompleted ? CohereTheme.deepGreen : CohereTheme.slate)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(occurrence.isCompleted ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    PriorityDot(priority: occurrence.todo.priority)

                    Text(occurrence.todo.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CohereTheme.ink)
                        .lineLimit(1)
                        .strikethrough(occurrence.isCompleted)

                    if let category = store.category(for: occurrence.todo.categoryID) {
                        CategoryChip(category: category, compact: true)
                    }
                }

                if !occurrence.todo.detail.isEmpty {
                    Text(occurrence.todo.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(CohereTheme.slate)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(CohereIconButtonStyle())
            .help("Edit")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.coral))
            .help("Delete")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CohereTheme.controlSurface, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
        .opacity(occurrence.isCompleted ? 0.48 : 1)
    }
}

private struct WeekDayColumn: View {
    @EnvironmentObject private var store: TodoStore
    let day: Date
    let index: Int
    let onAddTodo: (Date) -> Void
    @State private var isDropTargeted = false

    private var occurrences: [TodoOccurrence] {
        store.occurrences(on: day, includeCompleted: true)
    }

    private var remainingCount: Int {
        occurrences.filter { !$0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                dateHeader
                Spacer(minLength: 6)
                if remainingCount > 0 {
                    Text("\(remainingCount)")
                        .font(CohereTheme.monoLabel(10))
                        .foregroundStyle(CohereTheme.deepGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(CohereTheme.paleGreen, in: Capsule())
                }
            }

            if occurrences.isEmpty {
                Text("Clear")
                    .font(.system(size: 11))
                    .foregroundStyle(CohereTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
            } else {
                ForEach(occurrences.prefix(5)) { occurrence in
                    MonthOccurrencePill(occurrence: occurrence, isInFocusedMonth: true)
                        .contextMenu {
                            Button(occurrence.isCompleted ? "Mark incomplete" : "Mark complete") {
                                store.toggleCompletion(occurrence)
                            }
                            Button("Delete", role: .destructive) {
                                store.deleteTodo(id: occurrence.todo.id)
                            }
                        }
                }

                if occurrences.count > 5 {
                    Text("+\(occurrences.count - 5) more")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CohereTheme.deepGreen)
                        .padding(.leading, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(CalendarService.isSameDay(day, Date()) ? CohereTheme.paleGreen.opacity(0.34) : CohereTheme.panelSurface)
        .overlay(alignment: .trailing) {
            if index != 6 {
                Rectangle()
                    .fill(CohereTheme.hairline.opacity(0.62))
                    .frame(width: 1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onAddTodo(day)
            } label: {
                Label("New Todo on \(day.formatted(date: .abbreviated, time: .omitted))", systemImage: "plus")
            }
        }
        .onDrop(of: TodoDragPayload.types, isTargeted: $isDropTargeted) { providers in
            dropTodo(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                    .stroke(CohereTheme.deepGreen, lineWidth: 2)
                    .padding(3)
            }
        }
    }

    @ViewBuilder
    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(CohereTheme.monoLabel(11))
                .foregroundStyle(weekendColor(for: day) ?? CohereTheme.slate)
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 22, weight: CalendarService.isSameDay(day, Date()) ? .semibold : .regular))
                .foregroundStyle(weekendColor(for: day) ?? CohereTheme.ink)
        }
    }

    private func dropTodo(_ providers: [NSItemProvider]) -> Bool {
        TodoDragPayload.loadTodoID(from: providers) { id in
            store.moveTodo(id: id, toDay: day)
        }
    }
}

private struct MonthCalendarGrid: View {
    let days: [Date]
    let focusedDate: Date
    let onAddTodo: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let headerHeight: CGFloat = 36

    var body: some View {
        GeometryReader { proxy in
            let cellHeight = max(88, (proxy.size.height - headerHeight) / 6)

            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(CalendarSymbols.weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(CohereTheme.monoLabel(11))
                            .foregroundStyle(weekendColor(forWeekdayLabel: label) ?? CohereTheme.slate)
                            .frame(maxWidth: .infinity, minHeight: headerHeight)
                            .background(CohereTheme.softStone.opacity(0.24))
                            .overlay(alignment: .trailing) {
                                if label != CalendarSymbols.weekdayLabels.last {
                                    Rectangle()
                                        .fill(CohereTheme.hairline.opacity(0.62))
                                        .frame(width: 1)
                                }
                            }
                    }
                }

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element) { index, day in
                        MonthDayCell(
                            day: day,
                            index: index,
                            minHeight: cellHeight,
                            isInFocusedMonth: CalendarService.calendar.isDate(day, equalTo: focusedDate, toGranularity: .month),
                            onAddTodo: onAddTodo
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CohereTheme.panelSurface)
        .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }
}

private struct MonthDayCell: View {
    @EnvironmentObject private var store: TodoStore
    let day: Date
    let index: Int
    let minHeight: CGFloat
    let isInFocusedMonth: Bool
    let onAddTodo: (Date) -> Void
    @State private var isDropTargeted = false

    private var occurrences: [TodoOccurrence] {
        store.occurrences(on: day, includeCompleted: true)
    }

    private var remainingCount: Int {
        occurrences.filter { !$0.isCompleted }.count
    }

    private var completedCount: Int {
        occurrences.filter(\.isCompleted).count
    }

    private var showsCompletionMarker: Bool {
        !occurrences.isEmpty && day < CalendarService.startOfDay(Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 6) {
                    dateLabel

                    if showsCompletionMarker {
                        MonthCompletionMarker(completedCount: completedCount, totalCount: occurrences.count)
                    }
                }

                Spacer()

                if remainingCount > 0 {
                    Text("\(remainingCount)")
                        .font(CohereTheme.monoLabel(10))
                        .foregroundStyle(CohereTheme.deepGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(CohereTheme.paleGreen, in: Capsule())
                }
            }

            ForEach(occurrences.prefix(3)) { occurrence in
                MonthOccurrencePill(occurrence: occurrence, isInFocusedMonth: isInFocusedMonth)
            }

            if occurrences.count > 3 {
                Text("+\(occurrences.count - 3) more")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CohereTheme.deepGreen)
                    .padding(.leading, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(minHeight: minHeight, maxHeight: minHeight, alignment: .topLeading)
        .background(isInFocusedMonth ? CohereTheme.panelSurface : CohereTheme.softStone.opacity(0.24))
        .overlay(alignment: .trailing) {
            if index % 7 != 6 {
                Rectangle()
                    .fill(CohereTheme.hairline.opacity(0.62))
                    .frame(width: 1)
            }
        }
        .overlay(alignment: .bottom) {
            if index < 35 {
                Rectangle()
                    .fill(CohereTheme.hairline.opacity(0.62))
                    .frame(height: 1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onAddTodo(day)
            } label: {
                Label("New Todo on \(day.formatted(date: .abbreviated, time: .omitted))", systemImage: "plus")
            }
        }
        .onDrop(of: TodoDragPayload.types, isTargeted: $isDropTargeted) { providers in
            dropTodo(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CohereTheme.deepGreen, lineWidth: 2)
                    .padding(3)
            }
        }
    }

    @ViewBuilder
    private var dateLabel: some View {
        if CalendarService.isSameDay(day, Date()) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(CohereTheme.onPrimary)
                .frame(width: 24, height: 24)
                .background(CohereTheme.primary, in: Circle())
        } else {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(standardDateColor)
        }
    }

    private var standardDateColor: Color {
        if let weekend = weekendColor(for: day) {
            return isInFocusedMonth ? weekend : weekend.opacity(0.52)
        }
        return isInFocusedMonth ? CohereTheme.ink : CohereTheme.muted
    }

    private func dropTodo(_ providers: [NSItemProvider]) -> Bool {
        TodoDragPayload.loadTodoID(from: providers) { id in
            store.moveTodo(id: id, toDay: day)
        }
    }
}

private struct MonthCompletionMarker: View {
    let completedCount: Int
    let totalCount: Int

    private var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        ZStack {
            switch completionState {
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CohereTheme.deepGreen)
            case .strong:
                Circle()
                    .fill(CohereTheme.deepGreen)
                    .frame(width: 5, height: 5)
            case .steady:
                Circle()
                    .fill(CohereTheme.actionBlue)
                    .frame(width: 5, height: 5)
            case .low:
                Circle()
                    .fill(CohereTheme.coral)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(width: 14, height: 14)
        .help("\(completedCount) of \(totalCount) tasks completed")
    }

    private var completionState: CompletionState {
        if completedCount == totalCount {
            return .complete
        }
        if completionRate >= 0.7 {
            return .strong
        }
        if completionRate >= 0.3 {
            return .steady
        }
        return .low
    }

    private enum CompletionState {
        case complete
        case strong
        case steady
        case low
    }
}

private struct MonthOccurrencePill: View {
    @EnvironmentObject private var store: TodoStore

    let occurrence: TodoOccurrence
    let isInFocusedMonth: Bool

    @ViewBuilder
    var body: some View {
        if occurrence.isRecurring || occurrence.isCompleted {
            pillContent
        } else {
            pillContent
                .onDrag {
                    TodoDragPayload.provider(for: occurrence.todo)
                }
                .help("Drag to another day")
        }
    }

    private var pillContent: some View {
        HStack(spacing: 4) {
            if let category = store.category(for: occurrence.todo.categoryID) {
                CategoryPatternSwatch(category: category, size: 9)
            }

            Circle()
                .fill(accent)
                .frame(width: 5, height: 5)

            Text(occurrence.todo.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isInFocusedMonth ? textColor : CohereTheme.slate)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .strikethrough(occurrence.isCompleted)

            if occurrence.isRecurring {
                Image(systemName: "repeat")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(CohereTheme.deepGreen)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(fill, in: RoundedRectangle(cornerRadius: 5))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        }
        .opacity(occurrence.isCompleted ? 0.46 : 1)
    }

    private var accent: Color {
        switch occurrence.todo.priority {
        case .low:
            return CohereTheme.muted
        case .normal:
            return CohereTheme.actionBlue
        case .high:
            return CohereTheme.coral
        }
    }

    private var fill: Color {
        switch occurrence.todo.priority {
        case .low:
            return CohereTheme.softStone.opacity(0.66)
        case .normal:
            return CohereTheme.paleBlue
        case .high:
            return CohereTheme.coral.opacity(0.12)
        }
    }

    private var textColor: Color {
        switch occurrence.todo.priority {
        case .low:
            return CohereTheme.bodyMuted
        case .normal:
            return CohereTheme.actionBlue
        case .high:
            return CohereTheme.coral
        }
    }
}

private enum TodoDragPayload {
    static let types: [UTType] = [.plainText]

    private static let prefix = "voidx-todo:"

    static func provider(for todo: TodoItem) -> NSItemProvider {
        NSItemProvider(object: NSString(string: "\(prefix)\(todo.id.uuidString)"))
    }

    static func loadTodoID(
        from providers: [NSItemProvider],
        action: @escaping @MainActor (UUID) -> Void
    ) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            guard let todoID = todoID(from: item) else { return }
            Task { @MainActor in
                action(todoID)
            }
        }

        return true
    }

    private static func todoID(from item: NSSecureCoding?) -> UUID? {
        if let string = item as? String {
            return todoID(from: string)
        }

        if let string = item as? NSString {
            return todoID(from: string as String)
        }

        if let data = item as? Data,
           let string = String(data: data, encoding: .utf8) {
            return todoID(from: string)
        }

        return nil
    }

    private static func todoID(from string: String) -> UUID? {
        guard string.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(string.dropFirst(prefix.count)))
    }
}

private struct RecurringTodoRow: View {
    @EnvironmentObject private var store: TodoStore
    let todo: TodoItem
    let onEdit: () -> Void

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

                if let category = store.category(for: todo.categoryID) {
                    CategoryChip(category: category, compact: true)
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

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(CohereIconButtonStyle())
            .help("Edit")

            Button(role: .destructive) {
                store.deleteTodo(id: todo.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.coral))
            .help("Delete")
        }
        .padding(12)
        .background(CohereTheme.controlSurface)
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
    let onEdit: (TodoItem) -> Void

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
                        RecurringTodoRow(todo: todo, onEdit: { onEdit(todo) })
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
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .contentShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection.contains(option.value) ? CohereTheme.onPrimary : CohereTheme.ink)
                .background(selection.contains(option.value) ? CohereTheme.primary : CohereTheme.softStone)
                .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
                .contentShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
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

private struct MarkdownPreview: View {
    let markdown: String

    private var blocks: [MarkdownBlock] {
        BasicMarkdownParser.blocks(from: markdown)
    }

    var body: some View {
        ScrollView {
            if blocks.isEmpty {
                EmptyStateView(title: "Nothing to preview", subtitle: "Write a note to render Markdown.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CohereTheme.softStone.opacity(0.22), in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                .stroke(CohereTheme.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inlineText(text, font: headingFont(level), color: CohereTheme.ink)
                .padding(.top, level == 1 ? 4 : 2)

        case .paragraph(let text):
            inlineText(text, font: .system(size: 14), color: CohereTheme.ink)
                .lineSpacing(4)

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(CohereTheme.deepGreen)
                        inlineText(item, font: .system(size: 14), color: CohereTheme.ink)
                    }
                }
            }

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).")
                            .font(CohereTheme.monoLabel(12))
                            .foregroundStyle(CohereTheme.deepGreen)
                            .frame(width: 24, alignment: .trailing)
                        inlineText(item, font: .system(size: 14), color: CohereTheme.ink)
                    }
                }
            }

        case .quote(let text):
            inlineText(text, font: .system(size: 14), color: CohereTheme.bodyMuted)
                .lineSpacing(4)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CohereTheme.deepGreen.opacity(0.42))
                        .frame(width: 3)
                }

        case .code(let text):
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(CohereTheme.ink)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CohereTheme.controlSurface, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                        .stroke(CohereTheme.hairline, lineWidth: 1)
                }

        case .divider:
            Rectangle()
                .fill(CohereTheme.hairline)
                .frame(height: 1)
                .padding(.vertical, 4)
        }
    }

    private func inlineText(_ text: String, font: Font, color: Color) -> Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let attributed = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        return Text(attributed)
            .font(font)
            .foregroundStyle(color)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1:
            return .system(size: 28, weight: .semibold)
        case 2:
            return .system(size: 22, weight: .semibold)
        default:
            return .system(size: 17, weight: .semibold)
        }
    }
}

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case unorderedList([String])
    case orderedList([String])
    case quote(String)
    case code(String)
    case divider
}

private enum BasicMarkdownParser {
    static func blocks(from markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var unorderedItems: [String] = []
        var orderedItems: [String] = []
        var codeLines: [String] = []
        var isReadingCode = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
            paragraphLines.removeAll()
        }

        func flushUnordered() {
            guard !unorderedItems.isEmpty else { return }
            blocks.append(.unorderedList(unorderedItems))
            unorderedItems.removeAll()
        }

        func flushOrdered() {
            guard !orderedItems.isEmpty else { return }
            blocks.append(.orderedList(orderedItems))
            orderedItems.removeAll()
        }

        func flushInlineBlocks() {
            flushParagraph()
            flushUnordered()
            flushOrdered()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if isReadingCode {
                    blocks.append(.code(codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                } else {
                    flushInlineBlocks()
                }
                isReadingCode.toggle()
                continue
            }

            if isReadingCode {
                codeLines.append(rawLine)
                continue
            }

            guard !trimmed.isEmpty else {
                flushInlineBlocks()
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                flushInlineBlocks()
                blocks.append(.divider)
                continue
            }

            if let heading = heading(from: trimmed) {
                flushInlineBlocks()
                blocks.append(heading)
                continue
            }

            if let item = unorderedItem(from: trimmed) {
                flushParagraph()
                flushOrdered()
                unorderedItems.append(item)
                continue
            }

            if let item = orderedItem(from: trimmed) {
                flushParagraph()
                flushUnordered()
                orderedItems.append(item)
                continue
            }

            if let quote = quote(from: trimmed) {
                flushInlineBlocks()
                blocks.append(.quote(quote))
                continue
            }

            flushUnordered()
            flushOrdered()
            paragraphLines.append(trimmed)
        }

        if isReadingCode {
            blocks.append(.code(codeLines.joined(separator: "\n")))
        }
        flushInlineBlocks()
        return blocks
    }

    private static func heading(from line: String) -> MarkdownBlock? {
        let level = line.prefix { $0 == "#" }.count
        guard (1...3).contains(level) else { return nil }
        let remainder = line.dropFirst(level)
        guard remainder.first == " " else { return nil }
        let text = String(remainder.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return .heading(level: level, text: text)
    }

    private static func unorderedItem(from line: String) -> String? {
        for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func orderedItem(from line: String) -> String? {
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let remainder = line.dropFirst(digits.count)
        guard remainder.hasPrefix(". ") else { return nil }
        return String(remainder.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }

    private static func quote(from line: String) -> String? {
        guard line.hasPrefix(">") else { return nil }
        return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
    }
}

private struct NoteListItem: View {
    @EnvironmentObject private var store: TodoStore

    let note: NoteItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(note.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CohereTheme.ink)
                .lineLimit(1)

            HStack(spacing: 7) {
                Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(CohereTheme.slate)

                if let category = store.category(for: note.categoryID) {
                    CategoryChip(category: category, compact: true)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? CohereTheme.paleBlue : CohereTheme.controlSurface)
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

private func weekendColor(for date: Date) -> Color? {
    let weekday = CalendarService.calendar.component(.weekday, from: date)
    switch weekday {
    case 1:
        return CohereTheme.holidayRed
    case 7:
        return CohereTheme.saturdayBlue
    default:
        return nil
    }
}

private func weekendColor(forWeekdayLabel label: String) -> Color? {
    switch label {
    case "Sat":
        return CohereTheme.saturdayBlue
    case "Sun":
        return CohereTheme.holidayRed
    default:
        return nil
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
