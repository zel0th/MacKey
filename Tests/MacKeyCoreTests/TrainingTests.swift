import Foundation
import Testing
#if canImport(MacKeyCore)
@testable import MacKeyCore
#else
@testable import MacKey
#endif

@Suite("Typing behavior") struct TypingTests {
    let start = Date(timeIntervalSince1970: 1_000)
    @Test func mistakesDoNotAdvanceInRetryMode() {
        var engine = TypingEngine(text: "ab")
        let wrong = engine.type("x", at: start)
        #expect(!wrong)
        #expect(engine.cursor == 0)
        let first = engine.type("a", at: start.addingTimeInterval(1))
        #expect(first)
        let second = engine.type("b", at: start.addingTimeInterval(2))
        #expect(second)
        #expect(engine.isComplete)
        #expect(engine.errors == 1)
        #expect(abs(engine.accuracy - 200.0 / 3) < 0.001)
        #expect(engine.cpm(at: start.addingTimeInterval(50)) == 60)
    }
    @Test func correctionRequiresDelete() {
        var engine = TypingEngine(text: "ab", policy: .correction)
        engine.type("x", at: start)
        engine.type("a", at: start)
        #expect(engine.cursor == 0)
        #expect(engine.attempts == 1)
        engine.backspace()
        #expect(engine.pendingMistake == nil)
        engine.type("a", at: start.addingTimeInterval(1))
        #expect(engine.cursor == 1)
        #expect(engine.errors == 1)
    }
    @Test func flowErrorsAreExcludedFromSpeed() {
        var engine = TypingEngine(text: "ab", policy: .flow)
        engine.type("x", at: start)
        engine.type("b", at: start.addingTimeInterval(2))
        #expect(engine.isComplete)
        #expect(engine.correctCount == 1)
        #expect(engine.accuracy == 50)
        #expect(engine.cpm(at: start.addingTimeInterval(2)) == 30)
    }
    @Test func pausedTimeAndInputAreExcluded() {
        var engine = TypingEngine(text: "abc")
        engine.type("a", at: start)
        engine.pause(at: start.addingTimeInterval(2))
        engine.type("b", at: start.addingTimeInterval(3))
        #expect(engine.cursor == 1)
        engine.resume(at: start.addingTimeInterval(102))
        engine.type("b", at: start.addingTimeInterval(103))
        engine.type("c", at: start.addingTimeInterval(104))
        #expect(engine.elapsed(at: start.addingTimeInterval(200)) == 4)
        #expect(engine.cpm(at: start.addingTimeInterval(200)) == 45)
    }
    @Test func deleteDoesNotEraseErrorHistoryOrProduceNegativeCursor() {
        var engine = TypingEngine(text: "abc")
        engine.backspace(); engine.type("x", at: start); engine.type("a", at: start)
        engine.backspace(); engine.backspace()
        #expect(engine.cursor == 0)
        #expect(engine.correctCount == 0)
        #expect(engine.errors == 1)
    }
    @Test func completionFreezesInputAndClock() {
        var engine = TypingEngine(text: "ab")
        engine.type("a", at: start); engine.type("b", at: start.addingTimeInterval(1))
        engine.backspace(); engine.type("c", at: start.addingTimeInterval(20))
        #expect(engine.attempts == 2)
        #expect(engine.elapsed(at: start.addingTimeInterval(100)) == 1)
    }
    @Test func unicodeAndWhitespaceAreNormalized() {
        #expect(TypingEngine.normalize("  e\u{301}\n\tмир  ") == "é мир")
        #expect(TypingEngine(text: "  ").expected == nil)
    }
}
struct SeededRandom: RandomNumberGenerator {
    var state: UInt64 = 12345
    mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1442695040888963407; return state }
}
@Suite("Lessons and progress") struct LessonTests {
    @Test(arguments: PracticeLanguage.allCases, [1,2,3,4,5,6]) func lessonsOnlyContainUnlockedLetters(language: PracticeLanguage, level: Int) {
        var preferences = Preferences(); preferences.language = language; preferences.wordCount = 24
        var rng = SeededRandom()
        let text = LessonGenerator.generate(preferences: preferences, level: level, weaknesses: [:], using: &rng)
        #expect(!text.isEmpty)
        #expect(text.allSatisfy { $0 == " " || language.letters(level: level).contains($0) })
        #expect(text.split(separator: " ").count == 24)
    }
    @Test func decorationsAreReachableOnTheSelectedLayout() {
        var preferences = Preferences(); preferences.capitals = true; preferences.punctuation = true; preferences.numbers = true
        var rng = SeededRandom()
        let text = LessonGenerator.generate(preferences: preferences, level: 6, weaknesses: [:], supported: KeyboardLayout.russian.supported, using: &rng)
        #expect(text.allSatisfy { KeyboardLayout.russian.supported.contains($0) })
        #expect(text.contains(where: { $0.isNumber }))
        #expect(text.contains(where: { $0.isUppercase }))
    }
    @Test func weaknessWeightingChangesThePracticeDistribution() {
        var preferences = Preferences(); preferences.wordCount = 100
        var baselineRng = SeededRandom(); var weightedRng = SeededRandom()
        let baseline = LessonGenerator.generate(preferences: preferences, level: 1, weaknesses: [:], using: &baselineRng)
        let weighted = LessonGenerator.generate(preferences: preferences, level: 1, weaknesses: ["н": KeyPerformance(attempts: 20, errors: 20)], using: &weightedRng)
        #expect(weighted.filter { $0 == "н" }.count > baseline.filter { $0 == "н" }.count)
    }
    private func record(level: Int, accuracy: Double = 100, cpm: Double = 120) -> SessionRecord {
        var result = SessionRecord(date: .distantPast, preferences: Preferences(), level: level, engine: TypingEngine(text: "a"))
        result.accuracy = accuracy; result.cpm = cpm; return result
    }
    @Test func advancementNeedsTwoSuccessfulLessons() {
        #expect(Progression.nextLevel(current: 1, recent: [record(level: 1)]) == 1)
        #expect(Progression.nextLevel(current: 1, recent: [record(level: 1), record(level: 1)]) == 2)
        #expect(Progression.nextLevel(current: 2, recent: [record(level: 2, accuracy: 80)]) == 1)
        #expect(Progression.nextLevel(current: 6, recent: [record(level: 6), record(level: 6)]) == 6)
    }
    @Test func manualAndCustomDoNotUnlockAutomaticLessons() {
        var custom = record(level: 1); custom.mode = .custom
        #expect(Progression.nextLevel(current: 1, recent: [record(level: 1), custom]) == 1)
    }
    @Test func savedProgressRoundTrips() throws {
        var state = SavedState(); state.history = [record(level: 3)]; state.levels["ru|test"] = 3
        state.customTexts = [CustomText(title: "Текст", text: "Привет, мир!")]
        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(SavedState.self, from: data)
        #expect(restored.history.count == 1); #expect(restored.levels["ru|test"] == 3)
        #expect(restored.customTexts == state.customTexts)
    }
}
@Suite("Keyboard mapping") struct KeyboardTests {
    @Test(arguments: [KeyboardLayout.russianMac, .russian, .english, .ukrainian, .dvorak, .colemak]) func everyGlyphHasAnInputAndHint(layout: KeyboardLayout) throws {
        for character in layout.supported {
            let hint = try #require(layout.hint(for: character))
            #expect(layout.character(code: hint.code, shift: hint.shift, caps: false, option: hint.option) == character)
        }
    }
    @Test(arguments: KeyboardShape.allCases) func keyboardIncludesAllFunctionKeysAndUniqueCodes(shape: KeyboardShape) {
        let keys = KeyboardGeometry.keys(shape: shape)
        #expect(Set(keys.map(\.code)).count == keys.count)
        #expect(keys.filter { $0.label.hasPrefix("F") }.count == 12)
        #expect(keys.allSatisfy { $0.x >= 0 && $0.x + $0.width <= 15.001 && $0.y + $0.height <= 5.821 })
        #expect(keys.contains { $0.code == 10 } == (shape == .iso))
    }
    @Test func shiftAndCapsLockBehaveLikePhysicalKeys() {
        #expect(KeyboardLayout.english.character(code: 0, shift: false, caps: true) == "A")
        #expect(KeyboardLayout.english.character(code: 0, shift: true, caps: true) == "a")
        #expect(KeyboardLayout.english.character(code: 18, shift: false, caps: true) == "1")
        #expect(KeyboardLayout.russian.hint(for: "Н")?.code == 16)
    }
}

@Suite("Transcript pagination") struct TranscriptTests {
    @Test(arguments: [1, 8, 25, 44, 70]) func everyCharacterSurvivesWrapping(capacity: Int) {
        let characters = Array("Привет, мир! café 👩🏽‍💻 сверхдлинноесловобезпробелов и финал")
        let layout = TranscriptLayout(characters: characters, capacity: capacity)
        #expect(layout.lines.flatMap { Array(characters[$0]) } == characters)
        #expect(layout.lines.allSatisfy { !$0.isEmpty && $0.count <= capacity })
        for cursor in characters.indices {
            let visible = layout.page(containing: cursor)
            #expect(visible.count <= 2)
            #expect(visible.contains { $0.contains(cursor) })
        }
    }
    @Test func pageTurnsAndBackspaceKeepCursorVisible() {
        let layout = TranscriptLayout(characters: Array("one two three four five six"), capacity: 8)
        let first = layout.page(containing: 0)
        let boundary = first.last!.upperBound
        #expect(layout.page(containing: boundary).first?.lowerBound == boundary)
        #expect(layout.page(containing: boundary - 1) == first)
        #expect(layout.page(containing: 10_000).last == layout.lines.last)
        #expect(TranscriptLayout().page(containing: 0).isEmpty)
    }
    @Test func longLessonAndResizeDoNotLoseTheActiveCharacter() {
        let characters = Array(String(repeating: "слово ", count: 8_000))
        for width in [12, 34, 60] {
            let layout = TranscriptLayout(characters: characters, capacity: width)
            for cursor in stride(from: 0, to: characters.count, by: 239) {
                #expect(layout.page(containing: cursor).contains { $0.contains(cursor) })
            }
        }
    }
}

@Suite("Default layout") struct DefaultLayoutTests {
    @Test func russianPrefersNativeMacEvenWhenPCComesFirst() {
        var native = KeyboardLayout.russianMac
        native.id = KeyboardLayout.russianMacSystemID
        let layouts = [KeyboardLayout.russian, .english, .russianMac, native]
        #expect(Preferences().layoutID == native.id)
        #expect(KeyboardLayout.preferred(for: .ru, among: layouts) == native)
        #expect(KeyboardLayout.preferred(for: .en, among: layouts) == .english)
    }
    @Test func missingSystemLayoutFallsBackToMacPunctuation() {
        let layout = KeyboardLayout.preferred(for: .ru, among: [.russian, .english])
        #expect(layout == .russianMac)
        #expect(layout.character(code: 42, shift: false, caps: false) == "ё")
        #expect(layout.character(code: 44, shift: true, caps: false) == "?")
        #expect(layout.character(code: 22, shift: true, caps: false) == ",")
        #expect(layout.character(code: 26, shift: true, caps: false) == ".")
        #expect(layout.character(code: 21, shift: true, caps: false) == "%")
        #expect(layout.character(code: 10, shift: false, caps: false) == ">")
    }
    @Test func existingPCPreferenceSurvivesPersistence() throws {
        var settings = Preferences(); settings.layoutID = KeyboardLayout.russian.id
        let restored = try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(settings))
        #expect(restored.layoutID == "builtin.ru")
    }
}

@Suite("Statistics pagination") struct StatisticsPaginationTests {
    @Test(arguments: [0, 1, 8, 9, 24, 25, 65, 5_000], [8, 24])
    func pagesCoverEveryItemExactlyOnce(count: Int, size: Int) {
        let first = PageWindow(itemCount: count, pageSize: size, requestedIndex: 0)
        let pages = (0..<first.pageCount).map { PageWindow(itemCount: count, pageSize: size, requestedIndex: $0) }
        #expect(pages.flatMap { Array($0.range) } == Array(0..<count))
        #expect(pages.allSatisfy { $0.range.count <= size })
        #expect(!first.hasPrevious)
        #expect(pages.last?.hasNext == false)
    }
    @Test func shrinkingHistoryAndInvalidRequestsStayInBounds() {
        let last = PageWindow(itemCount: 9, pageSize: 8, requestedIndex: 999)
        #expect(last.index == 1 && last.range == 8..<9)
        #expect(last.hasPrevious && !last.hasNext)
        #expect(PageWindow(itemCount: 9, pageSize: 8, requestedIndex: -1).index == 0)
        #expect(PageWindow(itemCount: 0, pageSize: 8, requestedIndex: 2).range.isEmpty)
        #expect(PageWindow(itemCount: -1, pageSize: 0, requestedIndex: -1).pageCount == 1)
    }
}

@Suite("Custom text validation") struct TextValidationTests {
    @Test(arguments: [0, 1, 50_000, 50_001]) func lengthBoundary(count: Int) {
        let result = TextValidation(text: String(repeating: "a", count: count), supported: ["a", " "])
        #expect(result.characterCount == count)
        #expect(result.canStart == (count > 0 && count <= 50_000))
        #expect(result.isTooLong == (count > 50_000))
        if result.isTooLong { #expect(result.normalized.isEmpty && result.unsupported.isEmpty) }
    }
    @Test func normalizationAndUnsupportedCharactersAgreeWithEngine() {
        let result = TextValidation(text: "  e\u{301}\t🙂\n🙂  б ", supported: ["é", " "])
        #expect(result.normalized == "é 🙂 🙂 б")
        #expect(result.unsupported == ["б", "🙂"])
        #expect(!result.canStart)
        #expect(Array(result.normalized) == TypingEngine(text: result.normalized).characters)
        #expect(!TextValidation(text: " \n\t ", supported: [" "]).canStart)
    }
    @Test func keyboardLayersNeverMergeOrSplitGraphemes() throws {
        let layout = KeyboardLayout(id: "test", name: "Test", language: "en", glyphs: [
            0: KeyGlyph("a", "A", option: "¨", optionShift: "\u{0308}"),
            1: KeyGlyph("ß", "SS", option: "ab", optionShift: "👨‍👩‍👧‍👦")
        ])
        #expect(layout.supported == ["a", "A", "¨", "\u{0308}", "ß", "👨‍👩‍👧‍👦", " "])
        #expect(!layout.supported.contains("¨\u{0308}"))
        #expect(!layout.supported.contains("S"))
        for character in layout.supported {
            let hint = try #require(layout.hint(for: character))
            #expect(layout.character(code: hint.code, shift: hint.shift, caps: false, option: hint.option) == character)
        }
        #expect(TextValidation(text: "¨", supported: layout.supported).canStart)
        #expect(!TextValidation(text: "¨\u{0308}", supported: layout.supported).canStart)
    }
}

// The lock protects the test probe shared with the disk queue, not application state.
private final class WriteProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [(Int, Bool)] = []
    func append(_ value: Int) { lock.withLock { entries.append((value, Thread.isMainThread)) } }
    var values: [Int] { lock.withLock { entries.map(\.0) } }
    var usedMainThread: Bool { lock.withLock { entries.contains { $0.1 } } }
}

@Suite("Background persistence", .timeLimit(.minutes(1))) @MainActor struct PersistenceTests {
    @Test func writesCompleteStateAndPreservesSubmittedSnapshot() async throws {
        let folder = URL.temporaryDirectory.appending(path: "MacKey-persistence-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "state.json")
        let writer = StatePersistence(url: url)
        var state = SavedState()
        state.preferences.fontSize = 44
        state.levels["ru|test"] = 3
        state.customTexts = [CustomText(title: "Тест", text: "она")]
        state.history = [SessionRecord(date: .distantPast, preferences: state.preferences, level: 3, engine: TypingEngine(text: "она"))]
        writer.enqueue(state)
        state.preferences.fontSize = 22
        state.customTexts.removeAll()
        let error = await writer.flush()
        #expect(error == nil)
        let loaded = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: url))
        #expect(loaded.preferences.fontSize == 44)
        #expect(loaded.levels["ru|test"] == 3)
        #expect(loaded.customTexts.first?.text == "она")
        #expect(loaded.history.count == 1)
    }
    @Test func slowWritesAreOffMainActorAndCoalesceToNewestState() async throws {
        let gate = DispatchSemaphore(value: 0)
        defer { gate.signal() }
        let started = AsyncStream<Void>.makeStream()
        let probe = WriteProbe()
        let writer = StatePersistence { state in
            if state.preferences.fontSize == 22 {
                started.continuation.yield(())
                guard gate.wait(timeout: .now() + 10) == .success else { throw CocoaError(.fileWriteUnknown) }
            }
            probe.append(state.preferences.fontSize)
        }
        var state = SavedState(); state.preferences.fontSize = 22
        writer.enqueue(state)
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next() // The main actor remains responsive while disk is blocked.
        for size in 23...48 { state.preferences.fontSize = size; writer.enqueue(state) }
        async let first = writer.flush()
        async let second = writer.flush()
        gate.signal()
        let results = await (first, second)
        #expect(results.0 == nil && results.1 == nil)
        #expect(probe.values == [22, 48])
        #expect(!probe.usedMainThread)
        started.continuation.finish()
    }
    @Test func failureIsReportedAndLaterSaveCanRecover() async throws {
        let root = URL.temporaryDirectory.appending(path: "MacKey-failed-write-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let parent = root.appending(path: "blocked")
        try Data("preserve me".utf8).write(to: parent)
        let url = parent.appending(path: "state.json")
        let writer = StatePersistence(url: url)
        var errors: [String] = []
        writer.onError = { errors.append($0) }
        writer.enqueue(SavedState())
        let failed = await writer.flush()
        #expect(failed != nil && errors.count == 1)
        #expect(try String(contentsOf: parent, encoding: .utf8) == "preserve me")
        try FileManager.default.removeItem(at: parent)
        var newest = SavedState(); newest.preferences.fontSize = 48
        writer.enqueue(newest)
        let recovered = await writer.flush()
        #expect(recovered == nil && writer.lastError == nil)
        #expect(try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: url)).preferences.fontSize == 48)
    }
}
