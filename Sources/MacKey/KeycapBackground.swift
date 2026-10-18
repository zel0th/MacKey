import SwiftUI
import AppKit
import QuartzCore

/// Core Animation interpolates the existing vector key decoration without
/// asking SwiftUI to lay out the keyboard on every frame of the cue fade.
struct KeycapBackground: NSViewRepresentable {
    let iso: Bool
    let tint: Color
    let dark: Bool
    let target: Bool
    let pressed: Bool
    let reduceMotion: Bool

    func makeNSView(context: Context) -> DecorationView { DecorationView() }
    func updateNSView(_ view: DecorationView, context: Context) {
        view.update(iso: iso, tint: NSColor(tint), dark: dark, target: target, pressed: pressed, reduceMotion: reduceMotion)
    }

    @MainActor final class DecorationView: NSView {
        private let base = CAShapeLayer()
        private let fill = CAShapeLayer()
        private let border = CAShapeLayer()
        private var iso = false
        private var target = false
        private var initialized = false
        override var isFlipped: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        init() {
            super.init(frame: .zero)
            wantsLayer = true
            layer?.isGeometryFlipped = true
            border.fillColor = nil
            for shape in [base, fill, border] { layer?.addSublayer(shape) }
        }
        required init?(coder: NSCoder) { nil }

        func update(iso: Bool, tint: NSColor, dark: Bool, target: Bool, pressed: Bool, reduceMotion: Bool) {
            let animated = initialized && self.target != target && !reduceMotion
            self.iso = iso; self.target = target
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            base.fillColor = NSColor.white.withAlphaComponent(dark ? 0.025 : 0.55).cgColor
            let fillAlpha = dark ? (target ? 0.24 : pressed ? 0.19 : 0.065)
                                 : (target ? 0.26 : pressed ? 0.20 : 0.13)
            let strokeAlpha = dark ? (target ? 0.95 : pressed ? 0.65 : 0.26)
                                   : (target ? 1.0 : pressed ? 0.80 : 0.44)
            let fillColor = tint.withAlphaComponent(fillAlpha).cgColor
            let strokeColor = tint.withAlphaComponent(strokeAlpha).cgColor
            let width: CGFloat = target ? (dark ? 1.6 : 2.0) : 0.8
            // Explicit, interruptible animations start from the currently visible
            // values. Rapid typing replaces the previous fade instead of queuing it.
            if animated {
                animate(fill, property: "fillColor", from: fill.presentation()?.fillColor ?? fill.fillColor, to: fillColor)
                animate(border, property: "strokeColor", from: border.presentation()?.strokeColor ?? border.strokeColor, to: strokeColor)
                animate(border, property: "lineWidth", from: border.presentation()?.lineWidth ?? border.lineWidth, to: width)
            } else {
                fill.removeAllAnimations(); border.removeAllAnimations()
            }
            fill.fillColor = fillColor; border.strokeColor = strokeColor; border.lineWidth = width
            updatePaths()
            CATransaction.commit()
            initialized = true
        }

        private func animate(_ layer: CALayer, property: String, from: Any?, to: Any) {
            let animation = CABasicAnimation(keyPath: property)
            animation.fromValue = from; animation.toValue = to
            animation.duration = 0.12
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(animation, forKey: property)
        }
        override func layout() {
            super.layout()
            CATransaction.begin(); CATransaction.setDisableActions(true)
            updatePaths()
            CATransaction.commit()
        }
        private func updatePaths() {
            let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
            for shape in [base, fill, border] { shape.frame = bounds; shape.contentsScale = scale }
            let rect = CGRect(origin: .zero, size: bounds.size)
            let path = KeycapShape(iso: iso).path(in: rect).cgPath
            base.path = path; fill.path = path
            border.path = KeycapShape(iso: iso, insetAmount: border.lineWidth / 2).path(in: rect).cgPath
        }
        override func viewDidChangeBackingProperties() { super.viewDidChangeBackingProperties(); needsLayout = true }
    }
}
