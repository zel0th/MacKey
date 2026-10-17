import SwiftUI
import Charts
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct StatisticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    let store: TrainingStore
    @ViewState<SessionRecord?> private var selected = nil
    @ViewState<Section> private var section = .overview
    @ViewState<Int> private var historyPage = 0
    @ViewState<Int> private var keysPage = 0
    private enum Section: String, CaseIterable { case overview = "Обзор", keys = "Клавиши", history = "История" }
    private var history: [SessionRecord] { store.history }
    private var speedUnit: String { store.preferences.wordsPerMinute ? "слов/мин" : "сим/мин" }
    private func speed(_ cpm: Double) -> Double { cpm / (store.preferences.wordsPerMinute ? 5 : 1) }

    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "Ваш прогресс", subtitle: store.layout.name) { store.panel = nil }
            if history.isEmpty {
                ContentUnavailableView("Первый шаг впереди", systemImage: "chart.xyaxis.line", description: Text("Завершите урок в этой раскладке, чтобы увидеть скорость, точность и прогресс по клавишам."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Picker("Раздел статистики", selection: $section) {
                    ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 24)
                Group {
                    switch section {
                    case .overview: overview
                    case .keys: keys
                    case .history: sessions
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(24)
            }
            Divider()
            HStack {
                Text("Данные на вашем Mac · CSV включает все раскладки").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Экспорт CSV…") { store.exportHistory() }.disabled(store.saved.history.isEmpty)
            }.padding(20)
        }.frame(width: 860, height: 620)
        .sheet(item: $selected) { session in
            VStack(alignment: .leading, spacing: 18) {
                PanelHeading(title: "Результат занятия", subtitle: session.date.formatted(date: .long, time: .shortened)) { selected = nil }
                HStack(spacing: 24) {
                    metric("wind", String(Int(speed(session.cpm))), speedUnit)
                    metric("scope", "\(Int(session.accuracy))%", "точность")
                }
                Text("\(session.characters) верных символов · \(session.errors) ошибок · \(Int(session.duration)) секунд")
                Text("\(session.mode.title)\(session.mode == .custom ? "" : " · Урок \(session.level)")\(session.capitals ? " · Заглавные" : "")\(session.numbers ? " · Числа" : "")\(session.punctuation ? " · Пунктуация" : "")")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Готово") { selected = nil }.frame(maxWidth: .infinity, alignment: .trailing)
            }.padding(24).frame(width: 590)
        }
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                metric("trophy", String(Int(speed(history.map(\.cpm).max() ?? 0))), "рекорд, \(speedUnit)")
                metric("checkmark.circle", String(history.count), "занятий")
                metric("clock", String(Int(history.map(\.duration).reduce(0, +) / 60)), "минут практики")
            }
            HStack(spacing: 10) {
                ForEach(1...6, id: \.self) { level in
                    let sessions = history.filter { $0.level == level && $0.mode != .custom && $0.mode != .expert }
                    let stars = sessions.map(\.stars).max() ?? 0
                    VStack(spacing: 6) {
                        Text("Урок \(level)").font(.callout)
                        Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars)).foregroundStyle(MacKeyTheme.panelAccent(colorScheme))
                        Text(sessions.isEmpty ? "—" : "\(Int(speed(sessions.map(\.cpm).max() ?? 0))) \(speedUnit)").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Text("Скорость последних 60 занятий").font(.headline)
            Chart(Array(history.suffix(60))) { session in
                LineMark(x: .value("Дата", session.date), y: .value(speedUnit, speed(session.cpm))).foregroundStyle(MacKeyTheme.panelAccent(colorScheme)).interpolationMethod(.linear)
                PointMark(x: .value("Дата", session.date), y: .value(speedUnit, speed(session.cpm))).foregroundStyle(MacKeyTheme.panelAccent(colorScheme))
            }.chartYAxisLabel(speedUnit).frame(maxHeight: .infinity)
                .accessibilityLabel("График скорости последних занятий, \(speedUnit)")
        }
    }
    private var keys: some View {
        let entries = store.weaknesses.sorted { lhs, rhs in
            lhs.value.accuracy == rhs.value.accuracy ? lhs.key < rhs.key : lhs.value.accuracy < rhs.value.accuracy
        }
        let page = PageWindow(itemCount: entries.count, pageSize: 24, requestedIndex: keysPage)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Сначала — клавиши, которым нужно внимание").font(.headline)
            Text("Точность за последние 30 занятий в этой раскладке.").font(.callout).foregroundStyle(.secondary)
            if entries.isEmpty {
                ContentUnavailableView("Пока нет данных по клавишам", systemImage: "keyboard", description: Text("Они появятся после следующего завершённого урока."))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 12) {
                    ForEach(Array(entries[page.range]), id: \.key) { entry in
                        VStack(spacing: 5) {
                            Text(entry.key == " " ? "␣" : entry.key).font(.system(size: 24, design: .monospaced))
                            Text("\(Int(entry.value.accuracy))%").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity).frame(height: 74)
                            .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(entry.key == " " ? "Пробел" : entry.key), точность \(Int(entry.value.accuracy)) процентов, нажатий \(entry.value.attempts)")
                    }
                }
            }
            Spacer(minLength: 0)
            pageControls(page, total: entries.count, noun: "Клавиши", selection: $keysPage)
        }
    }
    private var sessions: some View {
        let entries = Array(history.reversed())
        let page = PageWindow(itemCount: entries.count, pageSize: 8, requestedIndex: historyPage)
        return VStack(alignment: .leading, spacing: 0) {
            HStack { Text("История занятий").font(.headline); Spacer(); Text("Выберите строку для подробностей").font(.caption).foregroundStyle(.secondary) }.padding(.bottom, 12)
            ForEach(Array(entries[page.range])) { session in
                Button { selected = session } label: {
                    HStack(spacing: 12) {
                        Text(session.date.formatted(date: .abbreviated, time: .shortened)).frame(width: 185, alignment: .leading)
                        Text(session.mode == .custom ? "Свой текст" : session.mode == .expert ? "Эксперт" : "Урок \(session.level)").frame(width: 100, alignment: .leading)
                        Spacer(minLength: 0)
                        Text("\(Int(speed(session.cpm))) \(speedUnit)").frame(width: 105, alignment: .trailing)
                        Text("\(Int(session.accuracy))%").frame(width: 55, alignment: .trailing)
                        Text("\(session.errors) ош.").frame(width: 55, alignment: .trailing)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }.font(.system(size: 13)).monospacedDigit().frame(height: 39).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Divider().opacity(0.4)
            }
            Spacer(minLength: 12)
            pageControls(page, total: entries.count, noun: "Занятия", selection: $historyPage)
        }
    }
    private func pageControls(_ page: PageWindow, total: Int, noun: String, selection: Binding<Int>) -> some View {
        HStack {
            Text(total == 0 ? "\(noun): 0" : "\(noun): \(page.range.lowerBound + 1)–\(page.range.upperBound) из \(total)").foregroundStyle(.secondary)
            Spacer()
            Button { selection.wrappedValue = page.index - 1 } label: { Image(systemName: "chevron.left") }.disabled(!page.hasPrevious).accessibilityLabel("Предыдущая страница")
            Text("\(page.index + 1) / \(page.pageCount)").monospacedDigit().frame(minWidth: 60)
            Button { selection.wrappedValue = page.index + 1 } label: { Image(systemName: "chevron.right") }.disabled(!page.hasNext).accessibilityLabel("Следующая страница")
        }.font(.callout)
    }
    private func metric(_ symbol: String, _ value: String, _ label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 23, weight: .light)).foregroundStyle(MacKeyTheme.panelAccent(colorScheme))
            VStack(alignment: .leading, spacing: 3) { Text(value).font(.system(size: 30, weight: .light)).monospacedDigit(); Text(label).font(.caption).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
        }.padding(14).frame(maxWidth: .infinity).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}
