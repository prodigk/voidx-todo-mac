import AppKit
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum CohereTheme {
    static let primary = Color(light: 0x17171c, dark: 0xf3f1ea)
    static let cohereBlack = Color.black
    static let ink = Color(light: 0x212121, dark: 0xf1f0ea)
    static let deepGreen = Color(light: 0x003c33, dark: 0x7dd8c0)
    static let darkNavy = Color(light: 0x071829, dark: 0x071829)
    static let canvas = Color(light: 0xffffff, dark: 0x0b1110)
    static let panelSurface = Color(light: 0xffffff, dark: 0x111a18)
    static let controlSurface = Color(light: 0xffffff, dark: 0x17221f)
    static let softStone = Color(light: 0xeeece7, dark: 0x202927)
    static let paleGreen = Color(light: 0xedfce9, dark: 0x18342a)
    static let paleBlue = Color(light: 0xf1f5ff, dark: 0x112238)
    static let hairline = Color(light: 0xd9d9dd, dark: 0x2f3a37)
    static let borderLight = Color(light: 0xe5e7eb, dark: 0x36413e)
    static let muted = Color(light: 0x93939f, dark: 0x8f9b98)
    static let slate = Color(light: 0x75758a, dark: 0xaab2ae)
    static let bodyMuted = Color(light: 0x616161, dark: 0xc5c9c3)
    static let coral = Color(light: 0xff7759, dark: 0xff9a82)
    static let holidayRed = Color(light: 0xd94a3a, dark: 0xff8e7d)
    static let saturdayBlue = Color(light: 0x1863dc, dark: 0x8fb7ff)
    static let actionBlue = Color(light: 0x1863dc, dark: 0x8fb7ff)
    static let formFocus = Color(light: 0x9b60aa, dark: 0xd5a6df)
    static let onPrimary = Color(light: 0xffffff, dark: 0x0b1110)
    static let onDark = Color.white
    static let darkBand = Color(light: 0x17171c, dark: 0x08110f)
    static let sidebarBackground = Color(light: 0x003c33, dark: 0x001b17)
    static let sidebarSelection = Color(light: 0xffffff, dark: 0xf3f1ea)
    static let sidebarSelectionText = Color(hex: 0x17171c)

    static let panelRadius: CGFloat = 16
    static let compactRadius: CGFloat = 8
    static let softRadius: CGFloat = 22

    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func monoLabel(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String
    let count: Int?
    var countLabel = "remaining"

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

            if let count {
                Text("\(count) \(countLabel)")
                    .font(CohereTheme.monoLabel(12))
                    .foregroundStyle(CohereTheme.onPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(CohereTheme.primary, in: Capsule())
            }
        }
        .padding(.bottom, 14)
    }
}

struct QuietPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(CohereTheme.panelSurface)
            .clipShape(RoundedRectangle(cornerRadius: CohereTheme.panelRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CohereTheme.panelRadius)
                    .stroke(CohereTheme.hairline, lineWidth: 1)
            }
            .shadow(color: CohereTheme.primary.opacity(0.035), radius: 18, x: 0, y: 12)
    }
}

struct DarkProductPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(CohereTheme.darkBand)
            .clipShape(RoundedRectangle(cornerRadius: CohereTheme.softRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CohereTheme.softRadius)
                    .stroke(CohereTheme.onDark.opacity(0.12), lineWidth: 1)
            }
    }
}

struct CoherePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(CohereTheme.onPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? CohereTheme.deepGreen : CohereTheme.primary, in: Capsule())
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

struct CohereIconButtonStyle: ButtonStyle {
    var foreground: Color = CohereTheme.ink
    var background: Color = CohereTheme.controlSurface

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 32, height: 32)
            .background(configuration.isPressed ? CohereTheme.softStone : background, in: Circle())
            .overlay {
                Circle().stroke(CohereTheme.hairline, lineWidth: 1)
            }
    }
}

struct CohereTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(CohereTheme.controlSurface, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CohereTheme.compactRadius)
                    .stroke(CohereTheme.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func cohereField() -> some View {
        modifier(CohereTextFieldStyle())
    }

    func appSurface() -> some View {
        self
            .padding(28)
            .background(CohereTheme.canvas)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private extension NSColor {
    convenience init(hex: UInt, alpha: Double = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: CGFloat(alpha)
        )
    }
}

extension Color {
    init(light: UInt, dark: UInt, alpha: Double = 1) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return NSColor(hex: bestMatch == .darkAqua ? dark : light, alpha: alpha)
        })
    }
}
