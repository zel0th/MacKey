import SwiftUI

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    let close: () -> Void
    @ViewState<Section> private var section = .basics
    private enum Section: String, CaseIterable { case basics = "Первые шаги", learning = "Обучение", shortcuts = "Клавиши" }

    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "Как заниматься", subtitle: "Небольшая практика каждый день лучше редкого марафона", close: close)
            Picker("Раздел справки", selection: $section) {
                ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 24)
            Group {
                switch section {
                case .basics: basics
                case .learning: learning
                case .shortcuts: shortcuts
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(24)
            Divider()
            HStack {
                Text("Сначала точность — скорость придёт с практикой.").font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button("Начать практику", action: close).buttonStyle(.borderedProminent)
            }.padding(20)
        }.frame(width: 860, height: 600)
    }
    private var basics: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                card("hand.raised.fingers.spread", "Исходная позиция", "Левая рука — Ф Ы В А, правая — О Л Д Ж. В английской раскладке — A S D F и J K L ;.\n\nБольшие пальцы лежат над пробелом. Метки на F и J помогают найти основной ряд на ощупь.")
                card("paintpalette", "Следуйте цвету", "У каждого из восьми пальцев свой пастельный цвет. Клавиша и контур пальца подсказывают следующее движение.\n\nShift нажимайте противоположной рукой. После нажатия возвращайте пальцы на основной ряд.")
            }
            card("keyboard", "Клавиатура вашего Mac", "Доступны ANSI и ISO, ряд F1–F12 и стрелки. F-клавиши не входят в текст упражнения; для их подсветки может понадобиться Fn. Яркостью и громкостью управляет macOS.")
        }
    }
    private var learning: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                card("graduationcap", "Шесть ступеней", "В автоматическом режиме два урока подряд с точностью от 96% и скоростью от 100 сим/мин повышают уровень. При точности ниже 85% — шаг назад.\n\nСложные буквы чаще встречаются в следующих уроках. Вручную можно выбрать любую ступень.")
                card("chart.xyaxis.line", "Что считается", "Точность — доля верных попыток. Скорость — верные символы за минуту активного времени; условное слово равно пяти символам.\n\nИсправление не отменяет ошибку. В истории сохраняются только завершённые уроки.")
            }
            card("star", "Звёзды и самостоятельный набор", "★ От 90% точности.    ★★ От 95% и 100 сим/мин.    ★★★ От 98% и 180 сим/мин.\nВ режиме «Эксперт» подсказки отключены — можно проверить свой навык.")
        }
    }
    private var shortcuts: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 0) {
                shortcut("Return / ⌘R", "Новый урок")
                shortcut("Esc / ⌘P", "Пауза и продолжение")
                shortcut("Delete", "Исправление")
                shortcut("⌘,", "Настройки")
                shortcut("⌘O", "Собственные тексты")
                shortcut("⌘⇧S", "Статистика")
                shortcut("⌃⌘F", "Полный экран")
            }.padding(.horizontal, 18).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            VStack(spacing: 18) {
                card("pause.circle", "Можно отвлечься", "При переходе в другое приложение или открытии настроек таймер останавливается. Вернувшись, снимите паузу и продолжайте в своём темпе.")
                card("delete.left", "Работа с ошибками", "Выберите в настройках: повторить верную клавишу, исправить через Delete или продолжить с ошибкой. Статистика сохраняет все попытки.")
            }.frame(width: 360)
        }
    }
    private func shortcut(_ key: String, _ action: String) -> some View {
        HStack { Text(action); Spacer(); Text(key).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary) }
            .frame(height: 44)
    }
    private func card(_ symbol: String, _ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.headline).foregroundStyle(MacKeyTheme.panelAccent(colorScheme))
            Text(text).font(.system(size: 14)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
}
