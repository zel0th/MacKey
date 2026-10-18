import SwiftUI
#if canImport(MacKeyCore)
import MacKeyCore
#endif

/// Original Bézier contours, drawn in keyboard units. The relaxed home-row pose
/// stays still so that changing a cue never stretches or distorts the anatomy.
struct HandsOverlay: View, Equatable {
    let active: Finger?
    @Environment(\.colorScheme) private var scheme
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { lhs.active == rhs.active }
    private static let contours = (0..<5).map { contour($0) }

    var body: some View {
        Canvas { context, size in
            let unit = size.width / 15
            for right in [false, true] {
                let fingers: [Finger] = right
                    ? [.rightLittle, .rightRing, .rightMiddle, .rightIndex, .thumbs]
                    : [.leftLittle, .leftRing, .leftMiddle, .leftIndex, .thumbs]
                for (index, finger) in fingers.enumerated() {
                    let transform = CGAffineTransform(a: right ? -unit : unit, b: 0, c: 0, d: unit, tx: right ? 13.4 * unit : 0, ty: 0)
                    let contour = Self.contours[index].applying(transform)
                    let selected = active == finger
                    let color = selected ? finger.color(scheme) : Color.primary
                    context.fill(contour, with: .color(color.opacity(selected ? 0.12 : 0.012)))
                    context.stroke(contour, with: .color(color.opacity(selected ? 0.72 : 0.19)), style: StrokeStyle(lineWidth: max(1.2, unit * 0.027), lineCap: .round, lineJoin: .round))
                }
            }
        }
        .mask {
            LinearGradient(stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.75),
                .init(color: .white.opacity(0.65), location: 0.86),
                .init(color: .clear, location: 0.99)
            ], startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func contour(_ finger: Int) -> Path {
        var p = Path()
        func move(_ x: Double, _ y: Double) { p.move(to: CGPoint(x: x, y: y)) }
        func curve(_ x: Double, _ y: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) {
            p.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: a, y: b), control2: CGPoint(x: c, y: d))
        }
        switch finger {
        case 0:
            move(1.38, 6.7)
            curve(1.58, 4.42, 1.16, 5.82, 1.20, 5.12)
            curve(1.98, 3.55, 1.72, 4.10, 1.83, 3.74)
            curve(2.25, 3.28, 2.06, 3.39, 2.14, 3.27)
            curve(2.56, 3.61, 2.43, 3.29, 2.55, 3.42)
            curve(2.33, 4.47, 2.60, 3.86, 2.43, 4.25)
            curve(2.31, 6.7, 2.03, 5.22, 2.14, 5.94)
        case 1:
            move(2.18, 6.7)
            curve(2.46, 4.48, 1.98, 5.74, 2.12, 5.22)
            curve(2.87, 3.54, 2.59, 4.11, 2.61, 3.80)
            curve(3.26, 3.15, 3.05, 3.37, 3.11, 3.18)
            curve(3.63, 3.38, 3.43, 3.10, 3.62, 3.20)
            curve(3.49, 4.13, 3.69, 3.64, 3.57, 3.90)
            curve(3.30, 5.02, 3.42, 4.42, 3.28, 4.68)
            curve(3.45, 6.7, 3.24, 5.68, 3.37, 6.16)
        case 2:
            move(3.20, 6.7)
            curve(3.50, 4.55, 3.01, 5.81, 3.17, 5.18)
            curve(3.91, 3.54, 3.71, 4.12, 3.66, 3.87)
            curve(4.23, 3.07, 4.03, 3.36, 4.06, 3.07)
            curve(4.65, 3.36, 4.43, 3.03, 4.61, 3.15)
            curve(4.53, 4.23, 4.74, 3.63, 4.58, 3.98)
            curve(4.36, 5.10, 4.49, 4.52, 4.37, 4.77)
            curve(4.57, 6.7, 4.31, 5.73, 4.48, 6.21)
        case 3:
            move(4.24, 6.7)
            curve(4.64, 4.60, 4.15, 5.88, 4.34, 5.22)
            curve(4.87, 3.68, 4.78, 4.26, 4.74, 3.99)
            curve(5.18, 3.22, 4.95, 3.40, 5.02, 3.21)
            curve(5.55, 3.55, 5.38, 3.21, 5.52, 3.37)
            curve(5.49, 4.40, 5.61, 3.85, 5.52, 4.12)
            curve(5.36, 5.19, 5.46, 4.66, 5.34, 4.92)
            curve(5.66, 6.7, 5.35, 5.74, 5.58, 6.23)
        default:
            move(4.82, 6.7)
            curve(5.34, 5.71, 4.94, 6.32, 5.04, 5.99)
            curve(5.92, 5.26, 5.53, 5.51, 5.73, 5.26)
            curve(6.27, 5.49, 6.15, 5.22, 6.27, 5.31)
            curve(6.15, 6.18, 6.28, 5.74, 6.15, 5.96)
            curve(6.18, 6.7, 6.12, 6.40, 6.17, 6.49)
        }
        p.closeSubpath()
        return p
    }
}
