import SwiftUI
import Charts
#if canImport(MacKeyCore)
import MacKeyCore
#endif

struct StatisticsView: View {
    let store: TrainingStore
    @ViewState<SessionRecord?> private var selected = nil
    private var history: [SessionRecord] { store.history }
    private var best: Int { Int(history.map(\.cpm).max() ?? 0) }
    var body: some View {
        VStack(spacing: 0) {
            PanelHeading(title: "Ваш прогресс", subtitle: "\(store.preferences.language.title) · \(store.layout.name)") { store.panel = nil }
            if history.isEmpty {
                ContentUnavailableView("Первый шаг впереди", systemImage: "chart.xyaxis.line", description: Text("Завершите урок, чтобы увидеть скорость, точность и прогресс по клавишам."))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 42) {
                            MetricView(symbol: "trophy", value: String(best / (store.preferences.wordsPerMinute ? 5 : 1)), label: store.preferences.wordsPerMinute ? "рекорд, слов/мин" : "рекорд, сим/мин")
                            MetricView(symbol: "checkmark.circle", value: String(history.count), label: "занятий")
                            MetricView(symbol: "clock", value: String(Int(history.map(\.duration).reduce(0,+) / 60)), label: "минут практики")
                        }
                        HStack(spacing: 10) {
                            ForEach([1,2,3,4,5,6], id: \.self) { level in
                                let sessions = history.filter { $0.level == level && $0.mode != .custom && $0.mode != .expert }
                                VStack(spacing: 8) {
                                    Text("Урок \(level)").font(.callout)
                                    Text(String(repeating: "★", count: sessions.map(\.stars).max() ?? 0) + String(repeating: "☆", count: 3 - (sessions.map(\.stars).max() ?? 0))).foregroundStyle(MacKeyTheme.accent)
                                    Text(sessions.isEmpty ? "—" : "\(Int(sessions.map(\.cpm).max() ?? 0)) сим/мин").font(.caption).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity).padding(.vertical, 16).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Скорость последних 60 занятий").font(.headline)
                            Chart(Array(history.suffix(60))) { session in
                                LineMark(x: .value("Дата", session.date), y: .value("Символы в минуту", session.cpm)).foregroundStyle(MacKeyTheme.accent).interpolationMethod(.linear)
                                PointMark(x: .value("Дата", session.date), y: .value("Символы в минуту", session.cpm)).foregroundStyle(MacKeyTheme.accent)
                            }.chartYAxisLabel("сим / мин").frame(height: 160)
                                .accessibilityLabel("График скорости последних занятий")
                        }
                        if !store.weaknesses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Клавиши, которым нужно внимание").font(.headline)
                                HStack(spacing: 8) {
                                    ForEach(store.weaknesses.sorted { $0.value.accuracy < $1.value.accuracy }.prefix(10), id: \.key) { entry in
                                        VStack(spacing: 5) {
                                            Text(entry.key == " " ? "␣" : entry.key.uppercased()).font(.title3.monospaced())
                                            Text("\(Int(entry.value.accuracy))%").font(.caption).foregroundStyle(.secondary)
                                        }.frame(width: 52).padding(.vertical, 12).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        HStack { Text("История занятий").font(.headline); Spacer(); Text("Нажмите на строку для подробностей").font(.caption).foregroundStyle(.secondary) }
                        LazyVStack(spacing: 0) {
                            ForEach(history.reversed()) { session in
                                Button { selected = session } label: {
                                    HStack {
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened)).frame(width: 190, alignment: .leading)
                                        Text(session.mode == .custom ? "Свой текст" : session.mode == .expert ? "Эксперт" : "Урок \(session.level)").frame(width: 100, alignment: .leading)
                                        Spacer()
                                        Text("\(Int(session.cpm / (store.preferences.wordsPerMinute ? 5 : 1))) \(store.preferences.wordsPerMinute ? "слов/мин" : "сим/мин")").frame(width: 100, alignment: .trailing)
                                        Text("\(Int(session.accuracy))%").frame(width: 60, alignment: .trailing)
                                        Text("\(session.errors) ош.").frame(width: 60, alignment: .trailing)
                                    }.font(.system(size: 12)).monospacedDigit().padding(.vertical, 11).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                Divider().opacity(0.4)
                            }
                        }
                    }.padding(24)
                }
            }
            HStack { Text("Данные хранятся на вашем Mac").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Экспорт CSV…") { store.exportHistory() }.disabled(store.saved.history.isEmpty) }.padding(20)
        }.frame(width: 850, height: 710)
        .sheet(item: $selected) { session in
            VStack(alignment: .leading, spacing: 18) {
                PanelHeading(title: "Результат занятия", subtitle: session.date.formatted(date: .long, time: .shortened)) { selected = nil }
                HStack(spacing: 30) {
                    MetricView(symbol: "wind", value: String(Int(session.cpm)), label: "символов / мин")
                    MetricView(symbol: "scope", value: String(Int(session.accuracy)), suffix: "%", label: "точность")
                }
                Text("\(session.characters) верных символов · \(session.errors) ошибок · \(Int(session.duration)) секунд")
                Text("\(session.mode.title) · Урок \(session.level)\(session.capitals ? " · Заглавные" : "")\(session.numbers ? " · Числа" : "")\(session.punctuation ? " · Пунктуация" : "")").foregroundStyle(.secondary)
                Button("Готово") { selected = nil }.frame(maxWidth: .infinity, alignment: .trailing)
            }.padding(24).frame(width: 590)
        }
    }
}
