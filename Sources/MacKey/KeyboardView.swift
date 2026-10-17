import SwiftUI
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct KeyboardView: View {
    let store: TrainingStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let unit = proxy.size.width / 15
                ZStack(alignment: .topLeading) {
                    ForEach(KeyboardGeometry.keys(shape: store.preferences.shape)) { key in
                        let hint = store.hint
                        let isTarget = store.hintsEnabled && store.preferences.showKeyHint && (hint?.code == key.code || (hint?.shift == true && key.code == shiftHint) || (hint?.option == true && key.code == 58))
                        let pressed = store.pressedCodes.contains(key.code) || (store.shift && (key.code == 56 || key.code == 60)) || (store.option && (key.code == 58 || key.code == 61)) || (store.capsLock && key.code == 57)
                        KeycapView(key: key, glyph: store.layout.glyphs[key.code], shifted: store.shift, caps: store.capsLock, target: isTarget, pressed: pressed, error: pressed && store.lastError, unit: unit)
                            .frame(width: key.width * unit - 6, height: key.height * unit - 6)
                            .position(x: key.x * unit + (key.width * unit - 6) / 2, y: key.y * unit + (key.height * unit - 6) / 2)
                    }
                    if store.preferences.showFingerHint {
                        HandsOverlay(active: store.hintsEnabled ? store.activeFinger : nil)
                    }
                }
            }.aspectRatio(15 / 6.55, contentMode: .fit)
            if store.preferences.showFingerHint {
                HStack(spacing: 16) {
                    HStack(spacing: 7) {
                        ForEach(Finger.allCases.filter { $0 != .thumbs }) { finger in
                            VStack(spacing: 5) {
                                Capsule().fill(finger.color(scheme).opacity(store.activeFinger == finger && store.hintsEnabled ? 1 : 0.35)).frame(height: 4)
                                Text(finger.title).font(.system(size: 9, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                            }.foregroundStyle(finger.color(scheme)).frame(maxWidth: .infinity)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(store.hintsEnabled ? "Следующий палец: \(store.activeFinger?.fullTitle ?? "большой")" : "Расположение пальцев")
            }
        }.animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: store.engine.cursor)
    }
    private var shiftHint: Int { store.activeFinger?.rawValue.hasPrefix("left") == true ? 60 : 56 }
}
struct KeycapView: View {
    let key: PhysicalKey
    let glyph: KeyGlyph?
    let shifted: Bool
    let caps: Bool
    let target: Bool
    let pressed: Bool
    let error: Bool
    let unit: Double
    @Environment(\.colorScheme) private var scheme
    private var tint: Color { error ? .red : key.finger.color(scheme) }
    private var label: String {
        guard let glyph else { return key.label }
        let isLetter = glyph.base.unicodeScalars.allSatisfy(CharacterSet.letters.contains)
        return (isLetter ? shifted != caps : shifted) ? glyph.shifted : glyph.base.uppercased()
    }
    private var accessibleLabel: String { key.code == 900 ? "Питание" : label.isEmpty ? "Пробел" : label }
    var body: some View {
        let shape = KeycapShape(iso: key.isoReturn)
        ZStack(alignment: .center) {
            shape.fill(scheme == .dark ? Color.white.opacity(0.025) : Color.white.opacity(0.55))
            shape.fill(tint.opacity(target ? 0.24 : pressed ? 0.19 : 0.065))
            shape.strokeBorder(tint.opacity(target ? 0.95 : pressed ? 0.65 : 0.26), lineWidth: target ? 1.6 : 0.8)
            if key.height < 0.8, let symbol = key.symbol {
                VStack(spacing: 3) {
                    Image(systemName: symbol).font(.system(size: max(9, unit * 0.16)))
                    Text(key.label).font(.system(size: max(7, unit * 0.11), weight: .medium))
                }.foregroundStyle(tint.opacity(0.85))
            } else if glyph != nil {
                Text(label).font(.system(size: unit * 0.31, weight: target ? .semibold : .medium, design: .rounded)).foregroundStyle(tint)
                if let glyph, glyph.shifted != glyph.base.uppercased() {
                    VStack { HStack { Text(glyph.shifted).font(.system(size: unit * 0.13)); Spacer() }; Spacer() }.padding(8).foregroundStyle(tint.opacity(0.62))
                }
                if key.code == 3 || key.code == 38 {
                    VStack { Spacer(); Capsule().fill(tint.opacity(0.6)).frame(width: 12, height: 2) }.padding(.bottom, 8)
                }
            } else {
                VStack {
                    if key.code == 36 { Image(systemName: "return").font(.system(size: 20)).padding(.top, 10) }
                    Spacer(minLength: 0)
                    Text(label).font(.system(size: max(8, unit * 0.145), weight: .medium))
                        .frame(maxWidth: .infinity, alignment: key.isoReturn ? .trailing : .leading)
                        .padding(9)
                }.foregroundStyle(tint.opacity(0.85))
            }
            if target && !pressed {
                VStack { Spacer(); HStack { Spacer(); Circle().fill(tint).frame(width: 4, height: 4) }.padding(7) }
            }
        }
        .shadow(color: target ? tint.opacity(0.13) : .clear, radius: 10)
        .scaleEffect(pressed ? 0.96 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibleLabel), \(key.finger.fullTitle)\(target ? ", следующая клавиша" : "")")
        .help("\(accessibleLabel) · \(key.finger.fullTitle)")
    }
}
struct KeycapShape: InsettableShape {
    var iso: Bool
    var insetAmount = 0.0
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard iso else { return Path(roundedRect: r, cornerRadius: 9) }
        // ISO return is an L-shaped vector key, occupying the two real keyboard rows.
        let notchX = r.minX + r.width / 6
        let notchY = r.minY + (r.height - 6) / 2
        var path = Path()
        path.move(to: CGPoint(x: r.minX + 7, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX - 7, y: r.minY))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 7), control: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 7))
        path.addQuadCurve(to: CGPoint(x: r.maxX - 7, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: notchX + 7, y: r.maxY))
        path.addQuadCurve(to: CGPoint(x: notchX, y: r.maxY - 7), control: CGPoint(x: notchX, y: r.maxY))
        path.addLine(to: CGPoint(x: notchX, y: notchY + 7))
        path.addQuadCurve(to: CGPoint(x: notchX - 7, y: notchY), control: CGPoint(x: notchX, y: notchY))
        path.addLine(to: CGPoint(x: r.minX + 7, y: notchY))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: notchY - 7), control: CGPoint(x: r.minX, y: notchY))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + 7))
        path.addQuadCurve(to: CGPoint(x: r.minX + 7, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        path.closeSubpath(); return path
    }
    func inset(by amount: CGFloat) -> some InsettableShape { var copy = self; copy.insetAmount += amount; return copy }
}
