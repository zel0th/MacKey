import Foundation

public enum Finger: String, CaseIterable, Codable, Identifiable, Sendable {
    case leftLittle, leftRing, leftMiddle, leftIndex, thumbs, rightIndex, rightMiddle, rightRing, rightLittle
    public var id: String { rawValue }
    public var title: String { switch self {
    case .leftLittle, .rightLittle: "Мизинец"
    case .leftRing, .rightRing: "Безымянный"
    case .leftMiddle, .rightMiddle: "Средний"
    case .leftIndex, .rightIndex: "Указательный"
    case .thumbs: "Большие"
    } }
    public var fullTitle: String { self == .thumbs ? "Большие пальцы" : "\(rawValue.hasPrefix("left") ? "Левый" : "Правый") · \(title.lowercased())" }
}
public struct KeyGlyph: Codable, Equatable, Sendable {
    public var base: String
    public var shifted: String
    public var option: String
    public var optionShift: String
    public init(_ base: String, _ shifted: String = "", option: String = "", optionShift: String = "") {
        self.base = base; self.shifted = shifted.isEmpty ? base.uppercased() : shifted
        self.option = option; self.optionShift = optionShift
    }
}
public struct KeyboardLayout: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var language: String
    public var glyphs: [Int: KeyGlyph]
    public init(id: String, name: String, language: String, glyphs: [Int: KeyGlyph]) {
        self.id = id; self.name = name; self.language = language; self.glyphs = glyphs
    }
    public var supported: Set<Character> {
        // Joining layers can merge combining marks into a different grapheme.
        // Only advertise values that character(code:...) can actually emit.
        Set(glyphs.values.flatMap { glyph in
            [glyph.base, glyph.shifted, glyph.option, glyph.optionShift].compactMap { value in
                value.count == 1 ? value.first : nil
            }
        } + [" "])
    }
    public func character(code: Int, shift: Bool, caps: Bool, option: Bool = false) -> Character? {
        if code == 49 { return " " }
        guard let glyph = glyphs[code] else { return nil }
        let isLetter = glyph.base.unicodeScalars.allSatisfy(CharacterSet.letters.contains)
        let upper = isLetter ? shift != caps : shift
        let value = option ? (upper ? glyph.optionShift : glyph.option) : (upper ? glyph.shifted : glyph.base)
        return value.count == 1 ? value.first : nil
    }
    public func hint(for character: Character) -> (code: Int, shift: Bool, option: Bool)? {
        if character == " " { return (49, false, false) }
        let c = String(character)
        for code in glyphs.keys.sorted() {
            guard let g = glyphs[code] else { continue }
            if g.base == c { return (code, false, false) }
            if g.shifted == c { return (code, true, false) }
        }
        for code in glyphs.keys.sorted() {
            guard let g = glyphs[code] else { continue }
            if g.option == c { return (code, false, true) }
            if g.optionShift == c { return (code, true, true) }
        }
        return nil
    }
    public static let numberCodes = [50,18,19,20,21,23,22,26,28,25,29,27,24]
    public static let topCodes = [12,13,14,15,17,16,32,34,31,35,33,30,42]
    public static let homeCodes = [0,1,2,3,5,4,38,40,37,41,39]
    public static let bottomCodes = [6,7,8,9,11,45,46,43,47,44]
    public static let russianMacSystemID = "com.apple.keylayout.Russian"
    /// Native Mac punctuation, also available when the system layout cannot be read.
    public static let russianMac: KeyboardLayout = {
        var layout = make(id: "builtin.ru.mac", name: "Русская — Mac (ЙЦУКЕН, встроенная)", language: "ru", rows: ["]1234567890-=", "йцукенгшщзхъё", "фывапролджэ", "ячсмитьбю/"], numberShift: "[!\"№%:,.;()_+", extra: KeyGlyph(">", "<"))
        layout.glyphs[42] = KeyGlyph("ё", "Ё")
        layout.glyphs[44] = KeyGlyph("/", "?")
        return layout
    }()
    public static func preferred(for language: PracticeLanguage, among layouts: [KeyboardLayout]) -> KeyboardLayout {
        if language == .ru {
            return layouts.first { $0.id == russianMacSystemID }
                ?? layouts.first { $0.id == russianMac.id } ?? russianMac
        }
        return layouts.first { $0.language == language.rawValue } ?? english
    }
    public static let russian: KeyboardLayout = make(id: "builtin.ru", name: "Русская — ПК (ЙЦУКЕН, встроенная)", language: "ru", rows: ["ё1234567890-=", "йцукенгшщзхъ\\", "фывапролджэ", "ячсмитьбю."], numberShift: "Ё!\"№;%:?*()_+", extra: KeyGlyph("<", ">"))
    public static let english: KeyboardLayout = make(id: "builtin.en", name: "Английская — США (QWERTY, встроенная)", language: "en", rows: ["`1234567890-=", "qwertyuiop[]\\", "asdfghjkl;'", "zxcvbnm,./"], numberShift: "~!@#$%^&*()_+", extra: KeyGlyph("§", "±"))
    public static let ukrainian: KeyboardLayout = make(id: "builtin.uk", name: "Українська · ЙЦУКЕН", language: "uk", rows: ["ґ1234567890-=", "йцукенгшщзхї\\", "фівапролджє", "ячсмитьбю."], numberShift: "Ґ!\"№;%:?*()_+", extra: KeyGlyph("'", "’"))
    public static let dvorak: KeyboardLayout = make(id: "builtin.dvorak", name: "Английская — Dvorak (встроенная)", language: "en", rows: ["`1234567890[]", "',.pyfgcrl/=\\", "aoeuidhtns-", ";qjkxbmwvz"], numberShift: "~!@#$%^&*(){}", extra: KeyGlyph("§", "±"))
    public static let colemak: KeyboardLayout = make(id: "builtin.colemak", name: "Английская — Colemak (встроенная)", language: "en", rows: ["`1234567890-=", "qwfpgjluy;[]\\", "arstdhneio'", "zxcvbkm,./"], numberShift: "~!@#$%^&*()_+", extra: KeyGlyph("§", "±"))
    private static func make(id: String, name: String, language: String, rows: [String], numberShift: String, extra: KeyGlyph) -> KeyboardLayout {
        var glyphs: [Int: KeyGlyph] = [:]
        let shifts: [Character: Character] = ["[":"{", "]":"}", "\\":"|", ";":":", "'":"\"", ",":"<", ".":">", "/":"?", "-":"_"]
        for (row, codes) in zip(rows, [numberCodes, topCodes, homeCodes, bottomCodes]) {
            for (c, code) in zip(row, codes) { glyphs[code] = KeyGlyph(String(c), shifts[c].map(String.init) ?? String(c).uppercased()) }
        }
        for (code, c) in zip(numberCodes, numberShift) { glyphs[code]?.shifted = String(c) }
        if language == "ru" || language == "uk" { glyphs[44]?.shifted = ","; glyphs[42]?.shifted = "/" }
        glyphs[10] = extra
        return KeyboardLayout(id: id, name: name, language: language, glyphs: glyphs)
    }
}
public struct PhysicalKey: Identifiable, Equatable, Sendable {
    public var id: Int { code }
    public let code: Int
    public let label: String
    public let symbol: String?
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let finger: Finger
    public var isoReturn = false
    public init(_ code: Int, _ label: String, _ x: Double, _ y: Double, _ width: Double = 1, _ height: Double = 1, _ finger: Finger = .rightLittle, symbol: String? = nil, isoReturn: Bool = false) {
        self.code = code; self.label = label; self.x = x; self.y = y; self.width = width; self.height = height; self.finger = finger; self.symbol = symbol; self.isoReturn = isoReturn
    }
}
public enum KeyboardGeometry {
    private static let isoKeys = makeKeys(shape: .iso)
    private static let ansiKeys = makeKeys(shape: .ansi)
    public static func keys(shape: KeyboardShape) -> [PhysicalKey] {
        shape == .iso ? isoKeys : ansiKeys
    }
    private static func makeKeys(shape: KeyboardShape) -> [PhysicalKey] {
        let fingers: [Finger] = [.leftLittle,.leftRing,.leftMiddle,.leftIndex,.leftIndex,.rightIndex,.rightIndex,.rightMiddle,.rightRing,.rightLittle,.rightLittle,.rightLittle,.rightLittle]
        var keys: [PhysicalKey] = [PhysicalKey(53, "esc", 0, 0, 1, 0.64, .leftLittle)]
        let codes = [122,120,99,118,96,97,98,100,101,109,103,111]
        let icons = ["sun.min", "sun.max", "rectangle.3.group", "magnifyingglass", "mic", "moon", "backward.end", "playpause", "forward.end", "speaker.slash", "speaker.wave.1", "speaker.wave.3"]
        for i in 0..<12 { keys.append(PhysicalKey(codes[i], "F\(i+1)", 1.05 + Double(i) * 1.075, 0, 1.025, 0.64, fingers[min(i,12)], symbol: icons[i])) }
        keys.append(PhysicalKey(900, "", 14, 0, 1, 0.64, .rightLittle, symbol: "power"))
        for (i, c) in KeyboardLayout.numberCodes.enumerated() {
            keys.append(PhysicalKey(c, "", Double(i), 0.82, 1, 1, i == 0 ? .leftLittle : fingers[min(i-1,12)]))
        }
        keys.append(PhysicalKey(51, "delete", 13, 0.82, 2, 1, .rightLittle))
        keys.append(PhysicalKey(48, "tab", 0, 1.82, 1.5, 1, .leftLittle))
        let top = shape == .iso ? Array(KeyboardLayout.topCodes.prefix(12)) : KeyboardLayout.topCodes
        for (i, c) in top.enumerated() { keys.append(PhysicalKey(c, "", 1.5 + Double(i), 1.82, c == 42 ? 1.5 : 1, 1, fingers[i])) }
        keys.append(PhysicalKey(57, "caps lock", 0, 2.82, 1.75, 1, .leftLittle))
        for (i, c) in KeyboardLayout.homeCodes.enumerated() { keys.append(PhysicalKey(c, "", 1.75 + Double(i), 2.82, 1, 1, fingers[i])) }
        if shape == .iso {
            keys.append(PhysicalKey(42, "", 12.75, 2.82, 1, 1, .rightLittle))
            keys.append(PhysicalKey(36, "return", 13.5, 1.82, 1.5, 2, .rightLittle, isoReturn: true))
        } else { keys.append(PhysicalKey(36, "return", 12.75, 2.82, 2.25, 1, .rightLittle)) }
        keys.append(PhysicalKey(56, "shift", 0, 3.82, shape == .iso ? 1.25 : 2.25, 1, .leftLittle))
        if shape == .iso { keys.append(PhysicalKey(10, "", 1.25, 3.82, 1, 1, .leftLittle)) }
        for (i,c) in KeyboardLayout.bottomCodes.enumerated() { keys.append(PhysicalKey(c, "", 2.25 + Double(i), 3.82, 1, 1, fingers[i])) }
        keys.append(PhysicalKey(60, "shift", 12.25, 3.82, 2.75, 1, .rightLittle))
        keys += [PhysicalKey(63,"fn",0,4.82,1,1,.leftLittle), PhysicalKey(59,"control",1,4.82,1,1,.leftLittle), PhysicalKey(58,"option",2,4.82,1,1,.leftLittle), PhysicalKey(55,"command",3,4.82,1.3,1,.leftLittle), PhysicalKey(49,"",4.3,4.82,5.1,1,.thumbs), PhysicalKey(54,"command",9.4,4.82,1.3,1,.rightLittle), PhysicalKey(61,"option",10.7,4.82,1.3,1,.rightLittle), PhysicalKey(123,"◀",12,5.32,1,0.5,.rightLittle), PhysicalKey(126,"▲",13,4.82,1,0.5,.rightLittle), PhysicalKey(125,"▼",13,5.32,1,0.5,.rightLittle), PhysicalKey(124,"▶",14,5.32,1,0.5,.rightLittle)]
        return keys
    }
}
