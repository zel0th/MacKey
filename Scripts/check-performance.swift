import Foundation

@main struct PerformanceCheck {
    @MainActor static func main() async throws {
        let base = URL.temporaryDirectory.appending(path: "MacKey-performance-\(UUID().uuidString)")
        setenv("MACKEY_DATA_DIR", base.path, 1)
        defer { try? FileManager.default.removeItem(at: base) }
        let store = TrainingStore()
        let text = String(String(repeating: "слово ", count: 8_334).prefix(50_000))
        var samples: [Double] = []
        for _ in 0..<5 {
            let start = DispatchTime.now().uptimeNanoseconds
            let result = TextValidation(text: text, supported: store.layout.supported)
            samples.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6)
            precondition(result.canStart && result.characterCount == 50_000)
        }
        print("50,000-character validation median: \(String(format: "%.3f", samples.sorted()[2])) ms")
        var engine = TypingEngine(text: "съешь ещё этих мягких французских булок да выпей чаю 0123456789.,!?")
        let startDate = Date(timeIntervalSince1970: 1_000)
        for (index, character) in engine.characters.enumerated() { engine.type(character, at: startDate.addingTimeInterval(Double(index) / 3)) }
        for count in [100, 1_000, 10_000] {
            store.saved.history = (0..<count).map { index in
                SessionRecord(date: startDate.addingTimeInterval(Double(index) * 300), preferences: store.preferences, level: index % 6 + 1, engine: engine)
            }
            let start = DispatchTime.now().uptimeNanoseconds
            for index in 0..<50 { store.update({ $0.fontSize = index % 2 == 0 ? 40 : 48 }, restartLesson: false) }
            let submitted = DispatchTime.now().uptimeNanoseconds
            let error = await store.flushPersistence()
            let finished = DispatchTime.now().uptimeNanoseconds
            precondition(error == nil)
            let data = try Data(contentsOf: base.appending(path: "state.json"))
            let state = try JSONDecoder().decode(SavedState.self, from: data)
            precondition(state.history.count == count && state.preferences.fontSize == 48)
            print("\(count) sessions, 50 preference changes: UI submission \(String(format: "%.3f", Double(submitted-start)/1e6)) ms; complete \(String(format: "%.3f", Double(finished-start)/1e6)) ms; JSON \(data.count) bytes")
        }
    }
}
