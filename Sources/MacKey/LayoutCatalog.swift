import Carbon
import Foundation
#if canImport(MacKeyCore)
import MacKeyCore
#endif

/// Read the layouts shipped with macOS without changing the user's input source.
@MainActor enum LayoutCatalog {
    static func displayName(id: String, original: String, language: String) -> String {
        if language == "ru" {
            switch id {
            case "com.apple.keylayout.Russian": return "Русская — Mac (ЙЦУКЕН)"
            case "com.apple.keylayout.RussianWin": return "Русская — ПК (ЙЦУКЕН)"
            case "com.apple.keylayout.Russian-Phonetic": return "Русская — фонетическая (QWERTY)"
            default: return "Русская — \(original)"
            }
        }
        return original
    }
    static func load() -> [KeyboardLayout] {
        var result: [KeyboardLayout] = [.russian, .english, .ukrainian, .dvorak, .colemak]
        let filter = [kTISPropertyInputSourceType!: kTISTypeKeyboardLayout!] as CFDictionary
        guard let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] else { return result }
        for source in sources {
            guard let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                  let namePointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName),
                  let dataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData),
                  let languagesPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { continue }
            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
            let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue() as String
            let languages = Unmanaged<CFArray>.fromOpaque(languagesPointer).takeUnretainedValue() as? [String] ?? []
            let language = languages.first?.split(separator: "-").first.map(String.init) ?? "en"
            guard PracticeLanguage.allCases.contains(where: { $0.rawValue == language }) else { continue }
            let data = Unmanaged<CFData>.fromOpaque(dataPointer).takeUnretainedValue()
            guard let bytes = CFDataGetBytePtr(data) else { continue }
            let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
            var glyphs: [Int: KeyGlyph] = [:]
            for code in KeyboardLayout.numberCodes + KeyboardLayout.topCodes + KeyboardLayout.homeCodes + KeyboardLayout.bottomCodes + [10] {
                func translate(_ modifiers: Int) -> String {
                    var dead: UInt32 = 0; var length = 0
                    var output = [UniChar](repeating: 0, count: 8)
                    let status = UCKeyTranslate(layout, UInt16(code), UInt16(kUCKeyActionDown), UInt32(modifiers >> 8), UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysMask), &dead, 8, &length, &output)
                    guard status == noErr, length > 0 else { return "" }
                    let text = String(utf16CodeUnits: output, count: length).precomposedStringWithCanonicalMapping
                    return text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) ? "" : text
                }
                let base = translate(0)
                if !base.isEmpty { glyphs[code] = KeyGlyph(base, translate(shiftKey), option: translate(optionKey), optionShift: translate(shiftKey | optionKey)) }
            }
            guard glyphs.count >= 35 else { continue }
            result.append(KeyboardLayout(id: id, name: displayName(id: id, original: name, language: language), language: language, glyphs: glyphs))
        }
        return result
    }
}
