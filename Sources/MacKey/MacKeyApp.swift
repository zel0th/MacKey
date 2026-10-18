import SwiftUI
import AppKit
#if canImport(MacKeyCore)
import MacKeyCore
#endif

@main
struct MacKeyApp: App {
    @NSApplicationDelegateAdaptor(MacKeyAppDelegate.self) private var appDelegate
    @ViewState<TrainingStore> private var store = TrainingStore()
    var body: some Scene {
        Window("MacKey", id: "main") {
            MainView(store: store)
                .onAppear { appDelegate.store = store }
                .preferredColorScheme(store.preferences.appearance == .system ? nil : store.preferences.appearance == .dark ? .dark : .light)
        }
        .defaultSize(width: 1220, height: 880)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("О программе MacKey") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [.applicationName: "MacKey", .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1", .credits: NSAttributedString(string: "Клавиатурный тренажёр для Mac\nSwiftUI · Векторная клавиатура · Локальная статистика")])
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) { Button("Настройки…") { store.panel = .settings }.keyboardShortcut(",") }
            CommandMenu("Тренировка") {
                Button("Новый урок") { store.restart() }.keyboardShortcut("r")
                Button(store.paused ? "Продолжить" : "Пауза") { store.togglePause() }.keyboardShortcut("p")
                Divider()
                Button("Мои тексты…") { store.panel = .library }.keyboardShortcut("o")
                Button("Статистика…") { store.panel = .statistics }.keyboardShortcut("s", modifiers: [.command, .shift])
                Button("Во весь экран") { NSApp.keyWindow?.toggleFullScreen(nil) }.keyboardShortcut("f", modifiers: [.control, .command])
            }
            CommandGroup(replacing: .help) { Button("Как заниматься в MacKey") { store.panel = .help } }
        }
    }
}
@MainActor final class MacKeyAppDelegate: NSObject, NSApplicationDelegate {
    weak var store: TrainingStore?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let store else { return .terminateNow }
        Task { @MainActor in
            let error = await store.flushPersistence()
            if let error {
                let alert = NSAlert()
                alert.messageText = "Не удалось сохранить прогресс"
                alert.informativeText = "\(error)\nМожно остаться в приложении и повторить сохранение."
                alert.addButton(withTitle: "Остаться")
                alert.addButton(withTitle: "Выйти без сохранения")
                sender.reply(toApplicationShouldTerminate: alert.runModal() == .alertSecondButtonReturn)
            } else { sender.reply(toApplicationShouldTerminate: true) }
        }
        return .terminateLater
    }
}
struct MainView: View {
    @Bindable var store: TrainingStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            MacKeyTheme.canvas(scheme).ignoresSafeArea()
            LinearGradient(colors: [MacKeyTheme.accent.opacity(0.055), .clear, Color.purple.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 18) {
                        metrics.padding(.top, 12)
                        practiceArea
                        if store.preferences.showKeyboard {
                            KeyboardView(store: store)
                                .frame(maxWidth: max(520, min(geometry.size.width - 88, (geometry.size.height - TranscriptView.height(for: Double(store.preferences.fontSize)) - 340) * 15 / 6.55)))
                                .padding(.top, 4)
                        }
                    }.padding(.horizontal, 44).padding(.bottom, 16).frame(maxWidth: 1280)
                        .frame(maxWidth: .infinity)
                }.scrollIndicators(.hidden)
                footer
            }
            KeyboardInput(store: store).frame(width: 0, height: 0)
        }
        }
        .tint(MacKeyTheme.accent)
        .frame(minWidth: 960, minHeight: 740)
        .sheet(item: $store.panel) { panel in
            Group {
                switch panel {
                case .settings: TrainingSettingsView(store: store)
                case .statistics: StatisticsView(store: store)
                case .library: TextLibraryView(store: store)
                case .help: HelpView { store.panel = nil }
                }
            }.preferredColorScheme(scheme)
        }
        .onChange(of: scenePhase) { if scenePhase != .active { store.pause() } }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in store.pause() }
        .alert("MacKey", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("Понятно") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
    private var header: some View {
        HStack(spacing: 18) {
            HStack(spacing: 9) { Image(systemName: "keyboard").foregroundStyle(MacKeyTheme.accent); Text("MacKey").font(.system(size: 15, weight: .semibold, design: .rounded)) }
            Spacer()
            Button { store.panel = .settings } label: {
                HStack(spacing: 8) {
                    Text(store.preferences.language.title)
                    Text("/").foregroundStyle(.tertiary)
                    Text(store.preferences.mode == .custom ? "Свой текст" : store.preferences.mode == .expert ? "Эксперт" : "Урок \(store.level) из 6")
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                }.font(.system(size: 12)).foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("Выбрать язык и урок")
            Spacer()
            Button { store.panel = .library } label: { Image(systemName: "text.book.closed") }.help("Мои тексты").accessibilityLabel("Мои тексты")
            Button { store.panel = .settings } label: { Image(systemName: "slider.horizontal.3") }.help("Настройки").accessibilityLabel("Настройки")
        }.buttonStyle(.plain).padding(.horizontal, 28).padding(.top, 15).padding(.bottom, 14)
        .background(.primary.opacity(0.018))
    }
    private var metrics: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 64) {
                MetricView(symbol: "wind", value: String(Int(store.engine.cpm(at: context.date) / (store.preferences.wordsPerMinute ? 5 : 1))), label: store.preferences.wordsPerMinute ? "слов / мин" : "символов / мин")
                MetricView(symbol: "scope", value: String(format: "%.0f", store.engine.accuracy), suffix: "%", label: "точность")
                MetricView(symbol: "delete.left", value: String(store.engine.errors), label: "ошибок")
            }.frame(maxWidth: .infinity)
        }
    }
    private var practiceArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 7) {
                    Circle().fill(store.engine.isComplete ? Color.green : MacKeyTheme.accent).frame(width: 5, height: 5)
                    Text(store.engine.isComplete ? "Урок завершён" : store.paused ? "Пауза" : store.engine.startedAt == nil ? "Начните печатать" : "Сохраняйте спокойный ритм")
                }
                Spacer()
                Text(store.preferences.mode == .custom ? "Свой текст" : store.preferences.mode == .expert ? "Без подсказок" : store.preferences.language.letters(level: store.level).map(String.init).joined(separator: "  "))
                    .lineLimit(1).truncationMode(.tail)
            }.font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            ZStack {
                TranscriptView(engine: store.engine, fontSize: Double(store.preferences.fontSize))
                    .opacity(store.paused && !store.engine.isComplete ? 0.16 : 1)
                if store.paused && !store.engine.isComplete {
                    Button { store.resume() } label: { Label("Продолжить тренировку", systemImage: "play.fill").padding(.horizontal, 8).padding(.vertical, 4) }.buttonStyle(.borderedProminent).controlSize(.large)
                }
            }.frame(height: TranscriptView.height(for: Double(store.preferences.fontSize)))
            ProgressView(value: store.engine.progress).tint(store.engine.isComplete ? .green : MacKeyTheme.accent).scaleEffect(x: 1, y: 0.5)
            HStack {
                if store.engine.pendingMistake != nil { Label("Нажмите Delete, чтобы исправить ошибку", systemImage: "delete.left").foregroundStyle(.red) }
                else if store.engine.isComplete { Text(store.promotion ?? "Готово. Нажмите Return для следующего урока.").foregroundStyle(.green) }
                else { Text(store.hintDescription).foregroundStyle(.secondary) }
                Spacer()
                Text("\(store.engine.cursor) / \(store.engine.characters.count)").monospacedDigit().foregroundStyle(.tertiary)
            }.font(.system(size: 11)).frame(height: 16)
        }
    }
    private var footer: some View {
        HStack {
            Button { store.panel = .help } label: { Label("Как заниматься", systemImage: "questionmark.circle") }
            Spacer()
            Button { store.togglePause() } label: { Image(systemName: store.paused ? "play" : "pause") }.help("Пауза · Esc").accessibilityLabel(store.paused ? "Продолжить" : "Пауза")
            Button { store.restart() } label: { Label("Новый урок", systemImage: "arrow.clockwise") }.help("Новый урок · Return")
            Spacer()
            Button { store.panel = .statistics } label: { Label("Статистика", systemImage: "chart.xyaxis.line") }
        }.font(.system(size: 12)).foregroundStyle(.secondary).buttonStyle(.plain).padding(.horizontal, 28).padding(.vertical, 18)
    }
}
struct MetricView: View {
    let symbol: String
    let value: String
    var suffix = ""
    let label: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 24, weight: .light)).foregroundStyle(.secondary).frame(width: 52, height: 52).background(.primary.opacity(0.045), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(size: 43, weight: .light, design: .rounded)); Text(suffix).font(.system(size: 17)) }.monospacedDigit()
                Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
            }.frame(minWidth: 96, alignment: .leading)
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(label): \(value)\(suffix)")
    }
}
extension TrainingStore {
    var hintDescription: String {
        guard hintsEnabled else { return "Точность важнее скорости" }
        guard let hint else { return engine.expected == nil ? "" : "Этот символ отсутствует в выбранной раскладке — смените её в настройках" }
        var parts: [String] = []
        if preferences.showFingerHint { parts.append(activeFinger?.fullTitle ?? "Большой палец") }
        if hint.shift { parts.append("Shift противоположной рукой") }
        if hint.option { parts.append("Option") }
        if capsLock { parts.append("Caps Lock включён") }
        return parts.joined(separator: "  ·  ")
    }
}
