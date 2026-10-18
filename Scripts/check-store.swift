import Foundation

@main struct StoreCheck {
    @MainActor static func main() async throws {
        let base = URL.temporaryDirectory.appending(path: "MacKey-store-check-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        setenv("MACKEY_DATA_DIR", base.path, 1)
        let store = TrainingStore()
        precondition(store.preferences.layoutID == KeyboardLayout.russianMacSystemID)
        store.update { $0.language = .en }
        precondition(store.layout.language == "en")
        store.update { $0.language = .ru }
        precondition(store.preferences.layoutID == KeyboardLayout.russianMacSystemID)
        store.update { $0.layoutID = KeyboardLayout.russian.id }
        let pcSaveError = await store.flushPersistence(); precondition(pcSaveError == nil)
        precondition(TrainingStore().preferences.layoutID == KeyboardLayout.russian.id)
        store.update { $0.layoutID = "missing.layout" }
        let missingSaveError = await store.flushPersistence(); precondition(missingSaveError == nil)
        precondition(TrainingStore().preferences.layoutID == KeyboardLayout.russianMacSystemID)
        let native = store.layouts.first { $0.id == KeyboardLayout.russianMacSystemID }!
        for (code, glyph) in KeyboardLayout.russianMac.glyphs {
            precondition(native.glyphs[code]?.base == glyph.base && native.glyphs[code]?.shifted == glyph.shifted)
        }
        store.update { $0.language = .en; $0.shape = .iso }
        store.addText(title: "English", text: "hello world")
        let englishID = store.customSelection
        store.update { $0.layoutID = KeyboardLayout.colemak.id }
        precondition(store.preferences.mode == .custom && String(store.engine.characters) == "hello world")
        store.update { $0.language = .ru }
        precondition(store.preferences.mode == .automatic && store.customSelection == nil)
        precondition(store.saved.customTexts.contains { $0.id == englishID })
        precondition(store.engine.characters.allSatisfy(store.layout.supported.contains))
        precondition(store.errorMessage != nil)
        store.update { $0.language = .en; $0.layoutID = KeyboardLayout.english.id; $0.shape = .iso }
        store.addText(title: "ISO", text: "§")
        precondition(store.preferences.mode == .custom)
        store.update { $0.shape = .ansi }
        precondition(store.preferences.mode == .automatic)
        precondition(store.engine.characters.allSatisfy(store.layout.supported.contains))
        let savedCount = store.saved.customTexts.count
        store.addText(title: "Unsupported", text: "🙂")
        store.addText(title: "Oversized", text: String(repeating: "a", count: 50_001))
        precondition(store.saved.customTexts.count == savedCount)
        store.selectText(store.saved.customTexts.first { $0.title == "ISO" }!)
        precondition(store.preferences.mode == .automatic)
        store.update { $0.language = .ru; $0.sound = false }
        store.addText(title: "Compatible", text: "она")
        store.update { $0.layoutID = KeyboardLayout.russian.id }
        precondition(store.preferences.mode == .custom && String(store.engine.characters) == "она")
        let historyCount = store.saved.history.count
        while let hint = store.hint { store.receive(code: hint.code, shift: hint.shift, caps: false, option: hint.option) }
        precondition(store.engine.isComplete && store.saved.history.count == historyCount + 1)
        let finalSaveError = await store.flushPersistence(); precondition(finalSaveError == nil)
        let restored = TrainingStore()
        precondition(restored.saved.history.count == historyCount + 1)
        precondition(restored.saved.customTexts.count == savedCount + 1)
        let state = base.appending(path: "state.json")
        try Data("invalid data".utf8).write(to: state)
        let corrupt = TrainingStore(); corrupt.persist(); _ = await corrupt.flushPersistence()
        precondition(corrupt.errorMessage != nil)
        let preserved = try String(contentsOf: state, encoding: .utf8)
        precondition(preserved == "invalid data")
        print("Verified defaults, language/layout/shape changes, valid and invalid custom texts, completed lesson persistence, reload and corrupt-file preservation")
    }
}
