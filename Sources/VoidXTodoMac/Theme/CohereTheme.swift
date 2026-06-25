import SwiftUI

enum CohereTheme {
    static let primary = Color(hex: 0x17171c)
    static let cohereBlack = Color.black
    static let ink = Color(hex: 0x212121)
    static let deepGreen = Color(hex: 0x003c33)
    static let darkNavy = Color(hex: 0x071829)
    static let canvas = Color.white
    static let softStone = Color(hex: 0xeeece7)
    static let paleGreen = Color(hex: 0xedfce9)
    static let paleBlue = Color(hex: 0xf1f5ff)
    static let hairline = Color(hex: 0xd9d9dd)
    static let borderLight = Color(hex: 0xe5e7eb)
    static let muted = Color(hex: 0x93939f)
    static let slate = Color(hex: 0x75758a)
    static let bodyMuted = Color(hex: 0x616161)
    static let coral = Color(hex: 0xff7759)
    static let actionBlue = Color(hex: 0x1863dc)
    static let formFocus = Color(hex: 0x9b60aa)

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
                Text("\(count) remaining")
                    .font(CohereTheme.monoLabel(12))
                    .foregroundStyle(CohereTheme.canvas)
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
            .background(CohereTheme.canvas)
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
            .background(CohereTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: CohereTheme.softRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CohereTheme.softRadius)
                    .stroke(CohereTheme.canvas.opacity(0.12), lineWidth: 1)
            }
    }
}

struct CoherePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(CohereTheme.canvas)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? CohereTheme.deepGreen : CohereTheme.primary, in: Capsule())
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

struct CohereIconButtonStyle: ButtonStyle {
    var foreground: Color = CohereTheme.ink
    var background: Color = CohereTheme.canvas

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
            .background(CohereTheme.canvas, in: RoundedRectangle(cornerRadius: CohereTheme.compactRadius))
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
    }
}
