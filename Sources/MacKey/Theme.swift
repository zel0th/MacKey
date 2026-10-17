import SwiftUI
#if canImport(MacKeyCore)
import MacKeyCore
#endif

// Explicit alias selects the macOS 14-compatible property wrapper even with SDK 27.
// The SDK 27 @State macro plugin is absent from standalone Command Line Tools.
typealias ViewState<Value> = SwiftUI.State<Value>

enum MacKeyTheme {
    static let accent = Color(red: 0.60, green: 0.76, blue: 0.88)
    static func panelAccent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent : Color(red: 0.24, green: 0.43, blue: 0.57)
    }
    static func canvas(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.12, green: 0.135, blue: 0.16) : Color(red: 0.94, green: 0.95, blue: 0.96)
    }
}
extension Finger {
    func color(_ scheme: ColorScheme) -> Color {
        let rgb: (Double, Double, Double) = switch self {
        case .leftLittle: (0.91,0.60,0.65)
        case .leftRing: (0.88,0.76,0.51)
        case .leftMiddle: (0.66,0.80,0.56)
        case .leftIndex: (0.53,0.77,0.85)
        case .thumbs: (0.77,0.79,0.83)
        case .rightIndex: (0.76,0.64,0.89)
        case .rightMiddle: (0.51,0.80,0.70)
        case .rightRing: (0.90,0.71,0.51)
        case .rightLittle: (0.91,0.59,0.73)
        }
        let factor = scheme == .dark ? 1.0 : 0.58
        return Color(red: rgb.0 * factor, green: rgb.1 * factor, blue: rgb.2 * factor)
    }
}
struct PanelHeading: View {
    let title: String
    let subtitle: String
    let close: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.title2.weight(.semibold)); Text(subtitle).font(.callout).foregroundStyle(.secondary) }
            Spacer()
            Button(action: close) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary) }.buttonStyle(.plain).help("Закрыть").accessibilityLabel("Закрыть")
        }.padding(24)
    }
}
