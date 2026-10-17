import SwiftUI
import AppKit

struct KeyboardInput: NSViewRepresentable {
    let store: TrainingStore
    func makeNSView(context: Context) -> CaptureView { CaptureView(store: store) }
    func updateNSView(_ nsView: CaptureView, context: Context) { nsView.store = store }
    static func dismantleNSView(_ nsView: CaptureView, coordinator: ()) { nsView.stop() }

    @MainActor final class CaptureView: NSView {
        var store: TrainingStore
        private var monitor: Any?
        override var acceptsFirstResponder: Bool { true }
        init(store: TrainingStore) {
            self.store = store; super.init(frame: .zero)
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
                let consumed = MainActor.assumeIsolated {
                    guard let self, self.window?.isKeyWindow == true, self.window?.attachedSheet == nil, self.store.panel == nil else { return false }
                    // Shortcuts and text fields keep normal macOS behavior.
                    if event.modifierFlags.contains(.command) { return false }
                    if self.window?.firstResponder is NSTextView { return false }
                    let flags = event.modifierFlags
                    self.store.shift = flags.contains(.shift); self.store.capsLock = flags.contains(.capsLock); self.store.option = flags.contains(.option)
                    if event.type == .flagsChanged { return false }
                    if event.type == .keyUp { self.store.pressedCodes.remove(Int(event.keyCode)); return false }
                    if event.isARepeat { return true }
                    self.store.receive(code: Int(event.keyCode), shift: flags.contains(.shift), caps: flags.contains(.capsLock), option: flags.contains(.option))
                    return true
                }
                return consumed ? nil : event
            }
        }
        required init?(coder: NSCoder) { nil }
        func stop() { if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil } }
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); window?.makeFirstResponder(self) }
        override func keyDown(with event: NSEvent) {}
    }
}
