import SwiftUI
import AppKit
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct TranscriptView: View {
    let engine: TypingEngine
    let fontSize: Double
    @ViewState<TranscriptLayout> private var layout = TranscriptLayout()

    static func height(for fontSize: Double) -> Double { fontSize * 2.5 + 24 }

    private func attributed(_ range: Range<Int>) -> AttributedString {
        var string = AttributedString()
        for index in range {
            var part = AttributedString(String(engine.characters[index]))
            if index < engine.cursor {
                part.foregroundColor = engine.accepted[index] ? Color.secondary.opacity(0.6) : Color.red
            } else if index == engine.cursor {
                part.foregroundColor = Color.black.opacity(0.9)
                part.backgroundColor = engine.pendingMistake == nil ? MacKeyTheme.accent : Color.red.opacity(0.8)
            } else { part.foregroundColor = .primary.opacity(0.9) }
            string += part
        }
        return string
    }
    var body: some View {
        GeometryReader { geometry in
            let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            let advance = ("M" as NSString).size(withAttributes: [.font: font]).width
            let capacity = max(1, Int((geometry.size.width - 8) / advance))
            let visible = layout.page(containing: engine.cursor).filter { $0.upperBound <= engine.characters.count }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(visible, id: \.lowerBound) { range in
                    Text(attributed(range))
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: true)
                        .frame(height: fontSize * 1.25, alignment: .leading)
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: capacity, initial: true) { layout = TranscriptLayout(characters: engine.characters, capacity: capacity) }
            .onChange(of: engine.characters) { layout = TranscriptLayout(characters: engine.characters, capacity: capacity) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Текст упражнения")
        .accessibilityValue(String(engine.characters))
    }
}
