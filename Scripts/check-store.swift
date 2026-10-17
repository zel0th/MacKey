import Foundation

@main struct StoreCheck {
    @MainActor static func main() throws {
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
        precondition(TrainingStore().preferences.layoutID == KeyboardLayout.russian.id)
        store.update { $0.layoutID = "missing.layout" }
        precondition(TrainingStore().preferences.layoutID == KeyboardLayout.russianMacSystemID)
        let native = store.layouts.first { $0.id == KeyboardLayout.russianMacSystemID }!
        for (code, glyph) in KeyboardLayout.russianMac.glyphs {
            precondition(native.glyphs[code]?.base == glyph.base && native.glyphs[code]?.shifted == glyph.shifted)
        }
        let state = base.appending(path: "state.json")
        try Data("invalid data".utf8).write(to: state)
        let corrupt = TrainingStore(); corrupt.persist()
        precondition(corrupt.errorMessage != nil)
        let preserved = try String(contentsOf: state, encoding: .utf8)
        precondition(preserved == "invalid data")
        print("Verified fresh defaults, language switching, saved PC selection, missing layout recovery, Mac glyphs and corrupt-file preservation")
    }
}
