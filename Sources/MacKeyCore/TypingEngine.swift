import Foundation

/// Value-type training state. Injected dates make timing and pauses deterministic in tests.
public struct TypingEngine: Sendable {
    public let characters: [Character]
    public let policy: ErrorPolicy
    public private(set) var cursor = 0
    public private(set) var attempts = 0
    public private(set) var errors = 0
    public private(set) var accepted: [Bool] = []
    public private(set) var pendingMistake: Character?
    public private(set) var keyPerformance: [String: KeyPerformance] = [:]
    public private(set) var startedAt: Date?
    public private(set) var finishedAt: Date?
    public private(set) var pausedAt: Date?
    private var pausedDuration: TimeInterval = 0
    public init(text: String, policy: ErrorPolicy = .retry) {
        characters = Array(Self.normalize(text)); self.policy = policy
    }
    public static func normalize(_ text: String) -> String {
        text.precomposedStringWithCanonicalMapping
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
    public var expected: Character? { cursor < characters.count ? characters[cursor] : nil }
    public var isComplete: Bool { !characters.isEmpty && cursor == characters.count }
    public var correctCount: Int { accepted.filter { $0 }.count }
    public var accuracy: Double { attempts == 0 ? 100 : Double(attempts - errors) / Double(attempts) * 100 }
    public var progress: Double { characters.isEmpty ? 0 : Double(cursor) / Double(characters.count) }
    public func elapsed(at date: Date) -> TimeInterval {
        guard let start = startedAt else { return 0 }
        return max(0, (finishedAt ?? pausedAt ?? date).timeIntervalSince(start) - pausedDuration)
    }
    public func cpm(at date: Date) -> Double {
        let duration = elapsed(at: date)
        return duration >= 1 ? Double(correctCount) * 60 / duration : 0
    }
    @discardableResult public mutating func type(_ character: Character, at date: Date) -> Bool {
        guard !isComplete, pausedAt == nil, pendingMistake == nil, let expected else { return false }
        if startedAt == nil { startedAt = date }
        attempts += 1
        let matches = character == expected
        var key = keyPerformance[String(expected), default: KeyPerformance()]
        key.attempts += 1
        if !matches { errors += 1; key.errors += 1 }
        keyPerformance[String(expected)] = key
        if matches || policy == .flow {
            accepted.append(matches); cursor += 1
            if isComplete { finishedAt = date }
        } else if policy == .correction { pendingMistake = character }
        return matches
    }
    public mutating func backspace() {
        guard !isComplete, pausedAt == nil else { return }
        if pendingMistake != nil { pendingMistake = nil; return }
        guard cursor > 0 else { return }
        cursor -= 1; accepted.removeLast()
    }
    public mutating func pause(at date: Date) {
        guard startedAt != nil, !isComplete, pausedAt == nil else { return }
        pausedAt = date
    }
    public mutating func resume(at date: Date) {
        guard let pausedAt else { return }
        pausedDuration += max(0, date.timeIntervalSince(pausedAt)); self.pausedAt = nil
    }
}
