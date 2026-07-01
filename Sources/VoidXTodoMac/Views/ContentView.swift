import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection? = .today
    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.light.rawValue

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .light
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)
                .frame(width: 300)
                .ignoresSafeArea(.container, edges: [.top, .bottom, .leading])

            Rectangle()
                .fill(CohereTheme.hairline)
                .frame(width: 1)
                .ignoresSafeArea(.container, edges: .vertical)

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CohereTheme.canvas)
        }
        .background(CohereTheme.canvas)
        .preferredColorScheme(appAppearance.colorScheme)
        .onOpenURL { url in
            guard url.scheme == "voidxtodo" else { return }
            if url.host == "today" {
                selection = .today
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
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

private struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        ZStack {
            CohereTheme.sidebarBackground
                .ignoresSafeArea(.container, edges: [.top, .bottom, .leading])

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VOIDX")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CohereTheme.onDark.opacity(0.62))

                    Text("Todo")
                        .font(CohereTheme.displayFont(36))
                        .foregroundStyle(CohereTheme.onDark)
                }
                .padding(.horizontal, 18)
                .padding(.top, 56)
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

                AppearanceSelector()
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)

                AppVersionText()
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

private struct SidebarRow: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
            .contentShape(RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }

    private var foregroundColor: Color {
        if isSelected {
            return CohereTheme.sidebarSelectionText
        }
        return isHovering ? CohereTheme.onDark : CohereTheme.onDark.opacity(0.78)
    }

    private var backgroundColor: Color {
        if isSelected {
            return CohereTheme.sidebarSelection
        }
        return isHovering ? CohereTheme.onDark.opacity(0.12) : Color.clear
    }
}

private struct AppVersionText: View {
    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        if let version, !version.isEmpty {
            return "v\(version)"
        }
        return "v1.0"
    }

    var body: some View {
        Text(versionText)
            .font(CohereTheme.monoLabel(10))
            .foregroundStyle(CohereTheme.onDark.opacity(0.38))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AppearanceSelector: View {
    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.light.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .light
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APPEARANCE")
                .font(CohereTheme.monoLabel(10))
                .foregroundStyle(CohereTheme.onDark.opacity(0.52))

            HStack(spacing: 14) {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        appAppearanceRaw = appearance.rawValue
                    } label: {
                        HStack(spacing: 6) {
                            RadioIndicator(isSelected: selectedAppearance == appearance)

                            Text(appearance.title)
                                .font(.system(size: 12, weight: selectedAppearance == appearance ? .medium : .regular))
                                .lineLimit(1)
                        }
                        .frame(minHeight: 22)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedAppearance == appearance ? CohereTheme.onDark : CohereTheme.onDark.opacity(0.66))
                    .help("\(appearance.title) mode")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct RadioIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(CohereTheme.onDark.opacity(isSelected ? 0.86 : 0.42), lineWidth: 1.2)
                .frame(width: 11, height: 11)

            if isSelected {
                Circle()
                    .fill(CohereTheme.onDark)
                    .frame(width: 5, height: 5)
            }
        }
    }
}
