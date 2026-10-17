import SwiftUI
import UniformTypeIdentifiers
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct TextLibraryView: View {
    let store: TrainingStore
    @ViewState<String> private var title = ""
    @ViewState<String> private var text = ""
    @ViewState<Bool> private var importing = false
    @ViewState<String?> private var message = nil
    private var unsupported: [String] {
        Array(Set(TypingEngine.normalize(text).filter { !store.layout.supported.contains($0) })).sorted().map(String.init)
    }
    private var canStart: Bool { !TypingEngine.normalize(text).isEmpty && unsupported.isEmpty && text.count <= 50_000 }
    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "Мои тексты", subtitle: "Тренируйтесь на том, что интересно читать") { store.panel = nil }
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("СОХРАНЁННЫЕ").font(.caption).foregroundStyle(.secondary)
                    if store.saved.customTexts.isEmpty { Text("Здесь появятся ваши упражнения").font(.callout).foregroundStyle(.secondary).padding(.top, 10) }
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(store.saved.customTexts) { item in
                                Button { title = item.title; text = item.text } label: {
                                    VStack(alignment: .leading, spacing: 4) { Text(item.title).lineLimit(2); Text("\(item.text.count) символов").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.frame(width: 190)
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Название упражнения", text: $title).textFieldStyle(.roundedBorder)
                    TextEditor(text: $text).font(.system(size: 15, design: .monospaced)).scrollContentBackground(.hidden).padding(10).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    Text("\(text.count) / 50 000 символов · абзацы и табуляция станут пробелами").font(.caption).foregroundStyle(.secondary)
                    if !unsupported.isEmpty { Text("Нет в раскладке «\(store.layout.name)»: \(unsupported.prefix(20).joined(separator: " ")). Выберите подходящую раскладку в настройках.").font(.caption).foregroundStyle(.orange) }
                    HStack {
                        Button("Открыть TXT…") { importing = true }
                        Button("Вставить") { if let value = NSPasteboard.general.string(forType: .string) { text = value } }
                        Spacer()
                        Button("Начать") {
                            if let existing = store.saved.customTexts.first(where: { $0.title == title && $0.text == TypingEngine.normalize(text) }) { store.selectText(existing) }
                            else { store.addText(title: title, text: text) }
                        }.buttonStyle(.borderedProminent).disabled(!canStart)
                    }
                }
            }.padding(24)
        }.frame(width: 820, height: 600)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 2_000_000 else { message = "Выберите текстовый файл размером до 2 МБ."; return }
                let content = try String(contentsOf: url, encoding: .utf8)
                guard content.count <= 50_000 else { message = "Разделите текст на фрагменты до 50 000 символов."; return }
                text = content; title = url.deletingPathExtension().lastPathComponent
            } catch { message = "Не удалось открыть UTF-8 текст: \(error.localizedDescription)" }
        }
        .alert("Импорт текста", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("Понятно") { message = nil } } message: { Text(message ?? "") }
    }
}
struct HelpView: View {
    let close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeading(title: "Печатайте спокойно и точно", subtitle: "Небольшая практика каждый день лучше редкого марафона", close: close)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    tip("hand.raised.fingers.spread", "Поставьте руки на основной ряд", "Левые пальцы — Ф Ы В А, правые — О Л Д Ж. В английской раскладке — A S D F и J K L ;. Большие пальцы лежат над пробелом. Метки на F и J помогут найти позицию на ощупь.")
                    tip("paintpalette", "Цвет показывает палец", "У каждого из восьми пальцев свой пастельный цвет. Подсвеченная клавиша и контур пальца подсказывают следующее движение. Shift нажимайте противоположной рукой.")
                    tip("graduationcap", "Шесть ступеней", "Начните с автоматического режима. Два урока подряд с точностью от 96% и скоростью от 100 сим/мин повышают уровень. При точности ниже 85% приложение возвращает на предыдущую ступень. Сложные для вас буквы чаще появляются в следующих уроках.")
                    tip("keyboard", "Полная клавиатура", "ANSI и ISO, ряд F1–F12, системные и стрелочные клавиши. Функциональные клавиши не являются текстом упражнения. Для получения F-событий на Mac может понадобиться Fn; яркость и громкость по-прежнему управляются системой.")
                    tip("command", "Управление", "Return — новый урок. Esc — пауза. Delete — исправление. ⌘R — перезапуск, ⌘P — пауза, ⌘O — свои тексты, ⌘⇧S — статистика, ⌘, — настройки. При уходе из приложения таймер останавливается.")
                    tip("chart.xyaxis.line", "Честный подсчёт", "Точность — доля верных попыток среди всех нажатий текстовых клавиш. Скорость — верные символы в минуту активного времени; условное слово равно пяти символам. Ошибка остаётся в статистике после исправления. Сохраняются завершённые уроки.")
                    tip("star", "Три звезды", "Одна — точность от 90%. Две — от 95% и 100 сим/мин. Три — от 98% и 180 сим/мин. В режиме «Эксперт» подсказки отключаются, чтобы оценить самостоятельный набор.")
                }.padding(24)
            }
            HStack { Spacer(); Button("Начать практику", action: close).buttonStyle(.borderedProminent) }.padding(20)
        }.frame(width: 650, height: 650)
    }
    private func tip(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: symbol).font(.system(size: 22, weight: .light)).foregroundStyle(MacKeyTheme.accent).frame(width: 30)
            VStack(alignment: .leading, spacing: 6) { Text(title).font(.headline); Text(text).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }
}
