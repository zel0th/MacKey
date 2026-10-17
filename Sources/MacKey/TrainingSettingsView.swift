import SwiftUI
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct TrainingSettingsView: View {
    let store: TrainingStore
    private func binding<T>(_ key: WritableKeyPath<Preferences, T>, restart: Bool = true) -> Binding<T> {
        Binding(get: { store.preferences[keyPath: key] }, set: { value in store.update({ $0[keyPath: key] = value }, restartLesson: restart) })
    }
    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "Настройки тренировки", subtitle: "Ваш язык, ваш темп, ваша клавиатура") { store.panel = nil }
            Form {
                Section("Обучение") {
                    Picker("Режим", selection: binding(\.mode)) {
                        ForEach(TrainingMode.allCases.filter { $0 != .custom }, id: \.self) { Text($0.title).tag($0) }
                        if store.preferences.mode == .custom { Text("Свой текст").tag(TrainingMode.custom) }
                    }
                    if store.preferences.mode == .manual {
                        Picker("Урок", selection: binding(\.manualLevel)) {
                            ForEach([1,2,3,4,5,6], id: \.self) { level in Text("\(level) · \(store.preferences.language.letters(level: level))").tag(level) }
                        }
                    }
                    if store.preferences.mode == .automatic {
                        Text("Урок \(store.level) из 6. Два занятия с точностью от 96% и скоростью от 100 сим/мин открывают следующий уровень.").font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle("Заглавные буквы", isOn: binding(\.capitals))
                    Toggle("Числа", isOn: binding(\.numbers))
                    Toggle("Пунктуация", isOn: binding(\.punctuation))
                    Picker("Длина урока", selection: binding(\.wordCount)) { ForEach([12,24,40,60], id: \.self) { Text("\($0) слов").tag($0) } }
                }
                Section("Язык и клавиатура") {
                    Picker("Язык", selection: binding(\.language)) { ForEach(PracticeLanguage.allCases) { Text($0.title).tag($0) } }
                    Picker("Раскладка", selection: binding(\.layoutID)) { ForEach(store.availableLayouts) { Text($0.name).tag($0.id) } }
                    Picker("Форма клавиатуры", selection: binding(\.shape)) { ForEach(KeyboardShape.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    Text("Раскладка действует внутри MacKey. Системный язык ввода не меняется. F1–F12 отображаются всегда; мультимедийные функции остаются под управлением macOS.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Во время набора") {
                    Picker("При ошибке", selection: binding(\.errorPolicy)) { ForEach(ErrorPolicy.allCases, id: \.self) { Text($0.title).tag($0) } }
                    Toggle("Подсказывать клавиши", isOn: binding(\.showKeyHint, restart: false))
                    Toggle("Подсказывать пальцы", isOn: binding(\.showFingerHint, restart: false))
                    Toggle("Показывать клавиатуру", isOn: binding(\.showKeyboard, restart: false))
                    Toggle("Звук ошибки", isOn: binding(\.sound, restart: false))
                    Toggle("Скорость в словах в минуту", isOn: binding(\.wordsPerMinute, restart: false))
                    Text("Одно условное слово = 5 символов. В режиме «Эксперт» подсказки отключены.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Оформление") {
                    Picker("Тема", selection: binding(\.appearance, restart: false)) { ForEach(Appearance.allCases, id: \.self) { Text($0.title).tag($0) } }
                    Picker("Размер текста", selection: binding(\.fontSize, restart: false)) { ForEach([22,26,30,34,40,44,48], id: \.self) { Text("\($0) пт").tag($0) } }
                }
            }.formStyle(.grouped)
            HStack { Text("Параметры сохраняются автоматически").font(.caption).foregroundStyle(.secondary); Spacer(); Button("К тренировке") { store.panel = nil; store.resume() }.buttonStyle(.borderedProminent) }.padding(20)
        }.frame(width: 620, height: 720)
    }
}
