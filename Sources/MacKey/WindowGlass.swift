import SwiftUI
import AppKit

/// A quiet window-wide frost; the expensive Liquid Glass treatment is limited
/// to navigation chrome, never repeated on the keys or the live typing text.
struct MacKeyWindowBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var opaque: Bool { reduceTransparency || contrast == .increased }
    var body: some View {
        ZStack {
            WindowFrost(scheme: scheme, opaque: opaque)
            MacKeyTheme.canvas(scheme).opacity(opaque ? 1 : scheme == .dark ? 0.76 : 0.70)
            if !opaque {
                LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.045 : 0.24), .clear, MacKeyTheme.accent.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.12 : 0.50), .clear, .white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct WindowFrost: NSViewRepresentable {
    let scheme: ColorScheme
    let opaque: Bool
    func makeNSView(context: Context) -> FrostView { FrostView() }
    func updateNSView(_ view: FrostView, context: Context) {
        view.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        view.isHidden = opaque
        view.opaqueBackground = opaque ? NSColor(MacKeyTheme.canvas(scheme)) : nil
        view.configureWindow()
    }

    @MainActor final class FrostView: NSVisualEffectView {
        var opaqueBackground: NSColor?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); configureWindow() }
        func configureWindow() {
            window?.isOpaque = opaqueBackground != nil
            window?.backgroundColor = opaqueBackground ?? .clear
        }
    }
}

private struct MacKeyGlassChrome: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.background {
            if reduceTransparency || contrast == .increased {
                MacKeyTheme.canvas(scheme)
            } else {
                // The compiler guard also keeps the macOS 14 fallback buildable
                // with Xcode 16, whose SDK does not declare Liquid Glass yet.
                #if compiler(>=6.2)
                if #available(macOS 26, *) {
                    Color.clear.glassEffect(.regular.tint(MacKeyTheme.accent.opacity(0.035)), in: Rectangle())
                } else {
                    Rectangle().fill(.thinMaterial)
                }
                #else
                Rectangle().fill(.thinMaterial)
                #endif
            }
        }
    }
}

extension View {
    func macKeyGlassChrome() -> some View { modifier(MacKeyGlassChrome()) }
    func macKeyGlassSheet() -> some View { presentationBackground { MacKeyWindowBackdrop() } }
}

struct AboutMacKeyView: View {
    let close: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "О программе MacKey", subtitle: "Клавиатурный тренажёр для Mac", close: close)
            VStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 80, height: 80)
                Text("MacKey").font(.title.weight(.semibold))
                Text("Версия \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.3")").foregroundStyle(.secondary)
                Text("SwiftUI · Векторная клавиатура · Локальная статистика")
                    .font(.callout).multilineTextAlignment(.center)
                Text("Полностью создано с помощью OpenAI Codex (ChatGPT)")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text("MacKey · 2026").font(.caption).foregroundStyle(.secondary)
            }.padding(28).frame(maxWidth: .infinity)
            HStack { Spacer(); Button("Готово", action: close).keyboardShortcut(.defaultAction) }
                .padding(20).macKeyGlassChrome()
        }.frame(width: 490)
    }
}
