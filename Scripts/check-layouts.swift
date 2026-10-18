import Foundation
@main struct Probe {
    @MainActor static func main() throws {
        let layouts = LayoutCatalog.load()
        var cases = 0
        for language in PracticeLanguage.allCases {
            let matching = layouts.filter { $0.language == language.rawValue }
            print("\(language.rawValue): \(matching.count) layouts")
            precondition(!matching.isEmpty, "Missing language \(language)")
            for layout in matching {
                for shape in KeyboardShape.allCases {
                    var physical = layout
                    if shape == .ansi { physical.glyphs.removeValue(forKey: 10) }
                    for character in physical.supported {
                        guard let hint = physical.hint(for: character) else { fatalError("Unreachable glyph \(layout.id): \(character)") }
                        precondition(physical.character(code: hint.code, shift: hint.shift, caps: false, option: hint.option) == character)
                    }
                    for glyph in physical.glyphs.values {
                        for value in [glyph.base, glyph.shifted, glyph.option, glyph.optionShift] where value.count == 1 {
                            precondition(physical.supported.contains(value.first!), "Rejected reachable glyph \(layout.id): \(value)")
                        }
                    }
                }
                for level in 1...6 {
                    var preferences = Preferences(); preferences.language = language; preferences.capitals = true; preferences.numbers = true; preferences.punctuation = true
                    let text = LessonGenerator.generate(preferences: preferences, level: level, weaknesses: [:], supported: layout.supported)
                    precondition(!text.isEmpty, "Empty lesson \(layout.name)")
                    for character in text {
                        guard let hint = layout.hint(for: character) else { fatalError("Missing hint \(layout.name): \(character)") }
                        precondition(layout.character(code: hint.code, shift: hint.shift, caps: false, option: hint.option) == character)
                    }
                    cases += 1
                }
            }
        }
        print("Verified \(layouts.count) layouts, \(cases) generated lessons")
    }
}
