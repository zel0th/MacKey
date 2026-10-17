import Foundation

public enum TrainingMode: String, Codable, CaseIterable, Sendable {
    case automatic, manual, expert, custom
    public var title: String { switch self {
    case .automatic: "Автоматически"
    case .manual: "Вручную"
    case .expert: "Эксперт"
    case .custom: "Свой текст"
    } }
}
public enum ErrorPolicy: String, Codable, CaseIterable, Sendable {
    case retry, correction, flow
    public var title: String { switch self {
    case .retry: "Повторить верную клавишу"
    case .correction: "Исправить через Delete"
    case .flow: "Продолжить с ошибкой"
    } }
}
public enum KeyboardShape: String, Codable, CaseIterable, Sendable { case ansi = "ANSI", iso = "ISO" }
public enum Appearance: String, Codable, CaseIterable, Sendable {
    case dark, light, system
    public var title: String { switch self { case .dark: "Тёмная"; case .light: "Светлая"; case .system: "Системная" } }
}
public struct Preferences: Codable, Equatable, Sendable {
    public var language: PracticeLanguage = .ru
    public var layoutID = "builtin.ru"
    public var mode: TrainingMode = .automatic
    public var manualLevel = 1
    public var capitals = false
    public var numbers = false
    public var punctuation = false
    public var showKeyboard = true
    public var showKeyHint = true
    public var showFingerHint = true
    public var sound = true
    public var wordsPerMinute = false
    public var shape: KeyboardShape = .iso
    public var appearance: Appearance = .dark
    public var errorPolicy: ErrorPolicy = .retry
    public var wordCount = 24
    public var fontSize = 40
    public init() {}
}
public struct KeyPerformance: Codable, Equatable, Sendable {
    public var attempts = 0
    public var errors = 0
    public var accuracy: Double { attempts == 0 ? 100 : 100 * Double(attempts - errors) / Double(attempts) }
    public init(attempts: Int = 0, errors: Int = 0) { self.attempts = attempts; self.errors = errors }
}
public struct SessionRecord: Codable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var language: PracticeLanguage
    public var layoutID: String
    public var level: Int
    public var mode: TrainingMode
    public var capitals: Bool
    public var numbers: Bool
    public var punctuation: Bool
    public var cpm: Double
    public var accuracy: Double
    public var errors: Int
    public var characters: Int
    public var duration: TimeInterval
    public var keys: [String: KeyPerformance]
    public var stars: Int { accuracy >= 98 && cpm >= 180 ? 3 : accuracy >= 95 && cpm >= 100 ? 2 : accuracy >= 90 ? 1 : 0 }
    public init(date: Date, preferences: Preferences, level: Int, engine: TypingEngine) {
        id = UUID(); self.date = date; language = preferences.language; layoutID = preferences.layoutID
        self.level = level; mode = preferences.mode; capitals = preferences.capitals
        numbers = preferences.numbers; punctuation = preferences.punctuation
        cpm = engine.cpm(at: date); accuracy = engine.accuracy; errors = engine.errors
        characters = engine.correctCount; duration = engine.elapsed(at: date); keys = engine.keyPerformance
    }
}
public struct SavedState: Codable, Sendable {
    public var version = 1
    public var preferences = Preferences()
    public var history: [SessionRecord] = []
    public var levels: [String: Int] = [:]
    public var customTexts: [CustomText] = []
    public init() {}
}
public struct CustomText: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var text: String
    public init(title: String, text: String) { self.title = title; self.text = text }
}
public enum Progression {
    public static func nextLevel(current: Int, recent: [SessionRecord]) -> Int {
        let current = min(6, max(1, current))
        guard let last = recent.last, last.mode == .automatic, last.level == current else { return current }
        if last.accuracy < 85 { return max(1, current - 1) }
        let pair = recent.suffix(2)
        if pair.count == 2 && pair.allSatisfy({ $0.mode == .automatic && $0.level == current && $0.accuracy >= 96 && $0.cpm >= 100 }) {
            return min(6, current + 1)
        }
        return current
    }
}
