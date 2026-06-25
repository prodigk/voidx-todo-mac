import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
        } detail: {
            switch selection ?? .today {
            case .today:
                TodayView()
            case .week:
                WeekView()
            case .month:
                MonthView()
            case .recurring:
                RecurringView()
            case .notes:
                NotesView()
            case .completed:
                CompletedView()
            }
        }
    }
}

private struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("VOIDX")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CohereTheme.canvas.opacity(0.62))

                Text("Todo")
                    .font(CohereTheme.displayFont(36))
                    .foregroundStyle(CohereTheme.canvas)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 22)

            VStack(spacing: 7) {
                ForEach(AppSection.allCases) { section in
                    SidebarRow(
                        section: section,
                        isSelected: selection == section,
                        action: { selection = section }
                    )
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            DarkProductPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCAL ONLY")
                        .font(CohereTheme.monoLabel(11))
                        .foregroundStyle(CohereTheme.canvas.opacity(0.55))
                    Text("Your routines stay on this Mac.")
                        .font(.system(size: 13))
                        .foregroundStyle(CohereTheme.canvas.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
        }
        .background(CohereTheme.deepGreen)
    }
}

private struct SidebarRow: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)

                Text(section.title)
                    .font(.system(size: 14, weight: .medium))

                Spacer()
            }
            .foregroundStyle(isSelected ? CohereTheme.primary : CohereTheme.canvas.opacity(0.78))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? CohereTheme.canvas : Color.clear, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        }
        .buttonStyle(.plain)
    }
}
