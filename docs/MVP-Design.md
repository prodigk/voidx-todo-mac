# VoidX Todo Mac MVP Design

## 1. MVP Scope

This first version is a personal, local-only macOS Todo app. It includes sidebar navigation, Today, Week, Month, Routines, Notes, and Completed sections; Todo CRUD; daily, weekly, and monthly recurrence; JSON persistence; and seed data.

Excluded for v1: iCloud sync, notifications, login, collaboration, tags, complex search, external calendar sync, and mobile support.

## 2. Screen Structure

- Sidebar: Today, Week, Month, Routines, Notes, Completed.
- Today: date header, remaining count, focused Todo list, quick-add composer.
- Week: 7-column calendar for the selected week with compact remaining Todo previews.
- Month: calendar grid for workload density and top Todo titles.
- Routines: recurring Todo management for daily, weekly, and monthly rules.
- Notes: lightweight independent note list and editor.
- Completed: completed Todo occurrences sorted by completion date.

## 3. User Flows

- Add a Todo quickly from Today, then optionally edit details and priority.
- Mark a Todo complete from any list or calendar preview.
- Review weekly or monthly workload density without opening a separate detail screen.
- Create daily, weekly, or monthly routine items from Routines and see them automatically in calendar views.
- Capture notes separately from Todo planning.

## 4. Data Model

- `TodoItem`: title, detail, due date, completion state, priority, optional recurrence rule, timestamps, completed occurrence dates.
- `RecurrenceRule`: weekly or monthly, weekdays or day of month, start/end dates, active state.
- `NoteItem`: title, body, timestamps.
- `TodoOccurrence`: view model produced by recurrence expansion for a specific day.

## 5. SwiftUI Component Structure

- `ContentView`: NavigationSplitView shell.
- Section views: `TodayView`, `WeekView`, `MonthView`, `RecurringView`, `NotesView`, `CompletedView`.
- Shared components: `TodoRow`, `QuickAddTodoView`, `TodoEditorSheet`.
- Store/services: `TodoStore`, `RecurrenceService`, `CalendarService`, `PersistenceService`.
- Theme: `CohereTheme` and small style modifiers aligned with `DESIGN-cohere.md`.

## 6. Folder Structure

```text
Sources/VoidXTodoMac
  Models/
  Stores/
  Services/
  Theme/
  Views/
```

## 7. Design Direction

The UI follows `DESIGN-cohere.md`: stark white canvas, near-black text, deep green accents, soft stone panels, precise spacing, thin rules, compact information density, and restrained rounded components. The signature detail is a calm calendar surface where Todo density is expressed with small deep-green count chips rather than decorative color.
