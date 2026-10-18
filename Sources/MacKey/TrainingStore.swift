import AppKit
import SwiftUI
import Observation
#if canImport(MacKeyCore)
import MacKeyCore
#endif

enum Panel: String, Identifiable { case settings, statistics, library, help, about; var id: String { rawValue } }

@MainActor @Observable final class TrainingStore {
    var saved: SavedState
    var engine = TypingEngine(text: "")
    var panel: Panel? { didSet { if panel != nil { pause() } } }
    var paused = false
    var pressedCodes: Set<Int> = []
    var shift = false
    var capsLock = false
    var option = false
    var lastError = false
    var errorMessage: String?
    var customSelection: UUID?
    var promotion: String?
    let layouts: [KeyboardLayout]
    private let storageURL: URL
    private let persistence: StatePersistence
    private var canSave = true
    private var recorded = false
    private var sessionPreferences = Preferences()
    private var sessionLevel = 1
    var preferences: Preferences { saved.preferences }
    var layout: KeyboardLayout {
        var selected = layouts.first { $0.id == preferences.layoutID }
            ?? KeyboardLayout.preferred(for: preferences.language, among: layouts)
        if preferences.shape == .ansi { selected.glyphs.removeValue(forKey: 10) }
        return selected
    }
    var progressKey: String { "\(preferences.language.rawValue)|\(preferences.layoutID)" }
    var level: Int { preferences.mode == .expert ? 6 : preferences.mode == .automatic ? saved.levels[progressKey, default: 1] : preferences.manualLevel }
    var history: [SessionRecord] { saved.history.filter { $0.language == preferences.language && $0.layoutID == preferences.layoutID } }
    var availableLayouts: [KeyboardLayout] {
        let matching = layouts.filter { $0.language == preferences.language.rawValue }
        return matching.isEmpty ? layouts : matching
    }
    var weaknesses: [String: KeyPerformance] {
        var result: [String: KeyPerformance] = [:]
        for session in history.suffix(30) {
            for (key, stats) in session.keys {
                result[key, default: KeyPerformance()].attempts += stats.attempts
                result[key, default: KeyPerformance()].errors += stats.errors
            }
        }
        return result
    }
    var hint: (code: Int, shift: Bool, option: Bool)? { engine.expected.flatMap { layout.hint(for: $0) } }
    var activeFinger: Finger? { hint.flatMap { hint in KeyboardGeometry.keys(shape: preferences.shape).first { $0.code == hint.code }?.finger } }
    var hintsEnabled: Bool { preferences.mode != .expert && !engine.isComplete }
    init() {
        layouts = LayoutCatalog.load()
        let base: URL
        if let override = ProcessInfo.processInfo.environment["MACKEY_DATA_DIR"] { base = URL(fileURLWithPath: override, isDirectory: true) }
        else { base = URL.applicationSupportDirectory.appending(path: "MacKey", directoryHint: .isDirectory) }
        storageURL = base.appending(path: "state.json")
        persistence = StatePersistence(url: storageURL)
        saved = SavedState()
        do {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                let loaded = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: storageURL))
                guard loaded.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
                saved = loaded
                saved.preferences.manualLevel = min(6, max(1, saved.preferences.manualLevel))
                saved.preferences.wordCount = min(100, max(5, saved.preferences.wordCount))
                saved.preferences.fontSize = min(48, max(22, saved.preferences.fontSize))
                saved.levels = saved.levels.mapValues { min(6, max(1, $0)) }
            }
        } catch { canSave = false; errorMessage = "Не удалось прочитать сохранённые данные. Исходный файл сохранён без изменений: \(storageURL.path). \(error.localizedDescription)" }
        if !layouts.contains(where: { $0.id == preferences.layoutID }) {
            saved.preferences.layoutID = KeyboardLayout.preferred(for: preferences.language, among: layouts).id
        }
        if saved.preferences.mode == .custom { saved.preferences.mode = .automatic }
        persistence.onError = { [weak self] error in self?.errorMessage = "Не удалось сохранить прогресс: \(error)" }
        restart()
    }
    func persist() {
        guard canSave else { return }
        persistence.enqueue(saved)
    }
    func flushPersistence() async -> String? { await persistence.flush() }
    func update(_ change: (inout Preferences) -> Void, restartLesson: Bool = true) {
        let oldLanguage = preferences.language
        change(&saved.preferences)
        if preferences.language != oldLanguage {
            saved.preferences.layoutID = KeyboardLayout.preferred(for: preferences.language, among: layouts).id
        }
        if restartLesson { restart() }
        persist()
    }
    func restart() {
        if preferences.mode == .custom {
            if let selected = saved.customTexts.first(where: { $0.id == customSelection }) {
                let validation = TextValidation(text: selected.text, supported: layout.supported)
                if !validation.canStart {
                    errorMessage = "Текст «\(selected.title)» сохранён в библиотеке, но его нельзя набрать в раскладке «\(layout.name)» на клавиатуре \(preferences.shape.rawValue). Начат обычный урок."
                    saved.preferences.mode = .automatic; customSelection = nil
                    persist()
                }
            } else {
                saved.preferences.mode = .automatic; customSelection = nil
            }
        }
        sessionPreferences = preferences; sessionLevel = level
        let text: String
        if preferences.mode == .custom, let selected = saved.customTexts.first(where: { $0.id == customSelection }) {
            text = selected.text
        } else {
            text = LessonGenerator.generate(preferences: preferences, level: level, weaknesses: weaknesses, supported: layout.supported)
        }
        engine = TypingEngine(text: text, policy: preferences.errorPolicy)
        recorded = false; lastError = false; paused = false; pressedCodes = []; promotion = nil
    }
    func pause() { engine.pause(at: Date()); paused = true; pressedCodes = [] }
    func resume() { engine.resume(at: Date()); paused = false }
    func togglePause() { paused ? resume() : pause() }
    func receive(code: Int, shift: Bool, caps: Bool, option: Bool) {
        guard panel == nil else { return }
        pressedCodes.insert(code)
        if code == 53 { togglePause(); return }
        if code == 36 || code == 76 { restart(); return }
        guard !paused else { return }
        if code == 51 { engine.backspace(); lastError = false; return }
        guard let character = layout.character(code: code, shift: shift, caps: caps, option: option), !engine.isComplete else { return }
        let hadPending = engine.pendingMistake != nil
        lastError = !engine.type(character, at: Date())
        if lastError && preferences.sound && !hadPending { NSSound(named: "Tink")?.play() }
        if engine.isComplete { finish() }
    }
    private func finish() {
        guard !recorded else { return }
        recorded = true
        saved.history.append(SessionRecord(date: engine.finishedAt ?? Date(), preferences: sessionPreferences, level: sessionLevel, engine: engine))
        if preferences.mode == .automatic {
            let next = Progression.nextLevel(current: level, recent: history)
            if next != level {
                promotion = next > level ? "Отлично! Следующий урок — \(next)." : "Закрепим знакомые буквы в уроке \(next)."
                saved.levels[progressKey] = next
            }
        }
        persist()
    }
    func addText(title: String, text: String) {
        let validation = TextValidation(text: text, supported: layout.supported)
        guard validateCustomText(validation) else { return }
        let item = CustomText(title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Мой текст" : title, text: validation.normalized)
        saved.customTexts.append(item); selectText(item)
    }
    func selectText(_ item: CustomText) {
        guard validateCustomText(TextValidation(text: item.text, supported: layout.supported)) else { return }
        customSelection = item.id; saved.preferences.mode = .custom
        panel = nil; persist(); restart()
    }
    private func validateCustomText(_ validation: TextValidation) -> Bool {
        guard validation.canStart else {
            errorMessage = validation.isTooLong ? "Разделите текст на фрагменты до 50 000 символов."
                : validation.normalized.isEmpty ? "Добавьте текст для тренировки."
                : "Этот текст нельзя набрать в раскладке «\(layout.name)». Выберите подходящую раскладку в настройках."
            return false
        }
        return true
    }
    func exportHistory() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.commaSeparatedText]; panel.nameFieldStringValue = "MacKey-statistics.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let rows = ["date,language,layout,mode,level,cpm,accuracy,errors,characters,seconds"] + saved.history.map { s in
            [s.date.ISO8601Format(), s.language.rawValue, s.layoutID, s.mode.rawValue, String(s.level), String(format: "%.2f", s.cpm), String(format: "%.2f", s.accuracy), String(s.errors), String(s.characters), String(format: "%.2f", s.duration)].map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
        }
        do { try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8) }
        catch { errorMessage = "Не удалось экспортировать статистику: \(error.localizedDescription)" }
    }
}
