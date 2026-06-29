import SwiftUI

struct CategorySelectionControl: View {
    @EnvironmentObject private var store: TodoStore
    @Binding var selectedCategoryID: UUID?

    var compact = false

    @State private var isCreating = false
    @State private var newCategoryName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Category", selection: $selectedCategoryID) {
                    Text("No category").tag(Optional<UUID>.none)
                    ForEach(store.categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                .labelsHidden()
                .frame(width: compact ? 150 : nil)

                Button {
                    isCreating.toggle()
                } label: {
                    Image(systemName: isCreating ? "minus" : "plus")
                }
                .buttonStyle(CohereIconButtonStyle())
                .help(isCreating ? "Cancel category" : "New category")
            }

            if isCreating {
                HStack(spacing: 8) {
                    TextField("New category", text: $newCategoryName)
                        .cohereField()
                        .onSubmit(createCategory)

                    Button {
                        createCategory()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.onPrimary, background: CohereTheme.primary))
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createCategory() {
        guard let id = store.addCategory(name: newCategoryName) else { return }
        selectedCategoryID = id
        newCategoryName = ""
        isCreating = false
    }
}

struct CategoryMenuButton: View {
    @EnvironmentObject private var store: TodoStore
    @Binding var selectedCategoryID: UUID?

    @State private var isPresented = false
    @State private var newCategoryName = ""

    private var selectedCategory: TodoCategory? {
        store.category(for: selectedCategoryID)
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 7) {
                if let selectedCategory {
                    CategoryPatternSwatch(category: selectedCategory, size: 14)
                    Text(selectedCategory.name)
                        .lineLimit(1)
                } else {
                    Image(systemName: "tag")
                    Text("Category")
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(CohereTheme.slate)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(selectedCategory.map { CategoryVisuals.foreground(for: $0) } ?? CohereTheme.bodyMuted)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedCategory.map { CategoryVisuals.fill(for: $0) } ?? CohereTheme.softStone.opacity(0.46), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(selectedCategory.map { CategoryVisuals.base(for: $0).opacity(0.24) } ?? CohereTheme.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(CohereTheme.monoLabel(11))
                    .foregroundStyle(CohereTheme.slate)

                VStack(alignment: .leading, spacing: 6) {
                    categoryOption(title: "No category", category: nil)

                    ForEach(store.categories) { category in
                        categoryOption(title: category.name, category: category)
                    }
                }

                Divider()

                HStack(spacing: 8) {
                    TextField("New category", text: $newCategoryName)
                        .cohereField()
                        .onSubmit(createCategory)

                    Button {
                        createCategory()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(CohereIconButtonStyle(foreground: CohereTheme.onPrimary, background: CohereTheme.primary))
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(14)
            .frame(width: 280)
            .background(CohereTheme.panelSurface)
        }
    }

    private func categoryOption(title: String, category: TodoCategory?) -> some View {
        Button {
            selectedCategoryID = category?.id
            isPresented = false
        } label: {
            HStack(spacing: 8) {
                if let category {
                    CategoryPatternSwatch(category: category, size: 14)
                } else {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 14)
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                if selectedCategoryID == category?.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CohereTheme.deepGreen)
                }
            }
            .foregroundStyle(category.map { CategoryVisuals.foreground(for: $0) } ?? CohereTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(category.map { CategoryVisuals.fill(for: $0) } ?? Color.clear, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
            .contentShape(RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
        }
        .buttonStyle(.plain)
    }

    private func createCategory() {
        guard let id = store.addCategory(name: newCategoryName) else { return }
        selectedCategoryID = id
        newCategoryName = ""
        isPresented = false
    }
}

struct CategoryChip: View {
    let category: TodoCategory
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            CategoryPatternSwatch(category: category, size: compact ? 12 : 14)

            Text(category.name)
                .font(.system(size: compact ? 10 : 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(CategoryVisuals.foreground(for: category))
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(CategoryVisuals.fill(for: category), in: Capsule())
        .overlay {
            Capsule()
                .stroke(CategoryVisuals.base(for: category).opacity(0.24), lineWidth: 1)
        }
        .help(category.name)
    }
}

struct CategoryPatternSwatch: View {
    let category: TodoCategory
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            context.fill(Path(ellipseIn: rect), with: .color(CategoryVisuals.fill(for: category)))

            var stripes = Path()
            let step: CGFloat = 5
            var x = -canvasSize.height
            while x < canvasSize.width {
                stripes.move(to: CGPoint(x: x, y: canvasSize.height))
                stripes.addLine(to: CGPoint(x: x + canvasSize.height, y: 0))
                x += step
            }
            context.stroke(stripes, with: .color(CategoryVisuals.base(for: category)), lineWidth: 1.25)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(CategoryVisuals.base(for: category).opacity(0.32), lineWidth: 1)
        }
    }
}

enum CategoryVisuals {
    static func base(for category: TodoCategory) -> Color {
        palette[normalizedIndex(category.colorIndex)].base
    }

    static func fill(for category: TodoCategory) -> Color {
        palette[normalizedIndex(category.colorIndex)].fill
    }

    static func foreground(for category: TodoCategory) -> Color {
        palette[normalizedIndex(category.colorIndex)].foreground
    }

    private static func normalizedIndex(_ index: Int) -> Int {
        let count = palette.count
        return ((index % count) + count) % count
    }

    private static let palette: [(base: Color, fill: Color, foreground: Color)] = [
        (Color(light: 0x6e56cf, dark: 0xa99af0), Color(light: 0xf3f0ff, dark: 0x211b3a), Color(light: 0x4b32a8, dark: 0xdad2ff)),
        (Color(light: 0x0e8f72, dark: 0x55d4b3), Color(light: 0xe9fbf5, dark: 0x12342d), Color(light: 0x006b53, dark: 0xb7f5e6)),
        (Color(light: 0xb7791f, dark: 0xf1bd68), Color(light: 0xfff7df, dark: 0x35270f), Color(light: 0x8a5200, dark: 0xffe0a8)),
        (Color(light: 0xc2418a, dark: 0xef89c2), Color(light: 0xffeff8, dark: 0x351628), Color(light: 0x9a2368, dark: 0xffc7e5)),
        (Color(light: 0x2563eb, dark: 0x8fb7ff), Color(light: 0xeff6ff, dark: 0x10243e), Color(light: 0x1d4ed8, dark: 0xd5e5ff)),
        (Color(light: 0x64748b, dark: 0x9aa7b8), Color(light: 0xf1f5f9, dark: 0x20272f), Color(light: 0x475569, dark: 0xd1d8e0))
    ]
}
