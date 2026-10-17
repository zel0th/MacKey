import Foundation

public enum PracticeLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case ru, en, uk, de, fr, es, pt, it, el, tr, mn
    public var id: String { rawValue }
    public var title: String { switch self {
    case .ru: "Русский"; case .en: "English"; case .uk: "Українська"; case .de: "Deutsch"
    case .fr: "Français"; case .es: "Español"; case .pt: "Português"; case .it: "Italiano"
    case .el: "Ελληνικά"; case .tr: "Türkçe"; case .mn: "Монгол"
    } }
    public var frequency: String { switch self {
    case .ru: "оеаинтсрвлкмдпуяыьгзбчйхжшюцщэфъё"
    case .en: "etaoinshrdlucmfwypvbgkjqxz"
    case .uk: "оаинвіетсрлкудмпяьзбгчйхжшюцїєщфґ"
    case .de: "enisratdhulcgmobwfkzpvüäößjqxy"
    case .fr: "esaitnrulodcmpévqfbghjàxèzyêçùâôîûëïüœ"
    case .es: "eaosrnidlctumpbgvyqhfzjñxkwáéíóúü"
    case .pt: "aeosrindmutclpvghqbfzjãáéçõíóêúâôxkwy"
    case .it: "eaionlrtscdupmvghfbzqàèéòìùxykwj"
    case .el: "αοτεινρσκημπλυσδωγθχφξζψβέάίόύήώϊϋΐΰς"
    case .tr: "aeinrlıkdmutysobüşzgçvhğöcfpj"
    case .mn: "аэнргийолтсдухбмвчжзшцөүпкфщъьыюеёя"
    } }
    public var words: [String] { vocabulary.split(separator: " ").map(String.init) }
    private var vocabulary: String { switch self {
    case .ru: "не на он она оно они и а о но ни нам нами мир мира мимо рано рана рамы море мера арена нора норма мина имя иное иона намёк нет нос сон тон торт тест тост рост сорт трон стена страна сторона трава свет слово снова волна вода дело дома дом дорога город год друг рука урок река книга окно время лето зима осень весна солнце небо облако берег ветер лес поле сад цветок жизнь любовь мысль память голос человек люди работа учёба клавиша пальцы печать строка скорость точность движение спокойно уверенно легко каждый новый день можно найти время для небольшой практики путь к цели начинается с первого шага хороший ритм помогает писать без ошибок ещё её ёж ёлка объём съёмка подъезд щука шёпот чай чашка юг язык быстрый мягкий хлеб эффект это экран"
    case .en: "a an at in on no not to it into tea ten tin tone note eat ate neat one none onion ion rain train air art rate near ear earth the this that there their then with which when what who how why we you your our us he she they them is are was were be been being have has had do does did can could will would should may more most some any all each other time day year life world word work home house water light sound wind tree green blue red small great new old good better best first next last hand finger key typing learn lesson practice calm clear slow fast speed accuracy rhythm focus change make take find give think write read book quick brown fox jumps over lazy dog zero quiet example joy"
    case .uk: "і а не на він вона воно вони ми ви ні але то та нам нами рано рана нора море мир ім'я мати тато стіна страна світ світло слово вода дім дорога місто рік друг рука урок річка книга вікно час літо зима осінь весна сонце небо берег вітер ліс поле сад квітка життя любов думка пам'ять голос людина люди робота навчання клавіша пальці друк рядок швидкість точність спокій легко кожен новий день ще їжа її їжак єдиний ґанок"
    case .de: "ein eine einer eines in an am im nein eins sein seine sie es ist mit wir er ihr die der das den dem und du ich nicht auch auf zu aus wie so nur nun man uns unser diese heute morgen zeit tag jahr leben welt wort arbeit haus wasser licht wind baum grün blau rot klein groß neu alt gut besser erste letzte hand finger taste lernen übung ruhig klar langsam schnell schön straße für über können müssen weiß heißt üben schreiben lesen buch"
    case .fr: "et en ne se ses est été tes te si sa le la les de des du un une il elle on nous vous ils elles ce ces ça qui que quoi oui non mais ou où mon ton son mes tes nos vos dans pour avec plus très bien tout tous ici rien sans sous entre jour nuit année vie monde mot travail maison eau lumière vent arbre vert bleu rouge petit grand nouveau bon meilleur main doigt touche apprendre écrire lire livre calme vite lent forêt cœur français garçon"
    case .es: "a e o es ese esa se ser era eres en no nos son sois el la los las de del un una uno unos yo tú él ella ello nosotros ustedes ellos que quien como cuando donde por para con sin más muy bien todo cada este esta esto mi tu su día noche año vida mundo palabra trabajo casa agua luz viento árbol verde azul rojo pequeño grande nuevo bueno mejor mano dedo tecla aprender escribir leer libro calma rápido corazón mañana español"
    case .pt: "a e o as os se ser era esse essa isso em nem no na nos nas eu tu ele ela nós vós eles elas de do da um uma uns que quem como quando onde por para com sem mais muito bem todo cada este esta meu teu seu dia noite ano vida mundo palavra trabalho casa água luz vento árvore verde azul vermelho pequeno grande novo bom melhor mão dedo tecla aprender escrever ler livro calma rápido coração manhã português lição"
    case .it: "a e o ai io no non noi ne era eri essere sei si se sono il lo la i gli le di del un uno una tu lui lei voi loro che chi come quando dove per con senza più molto bene tutto ogni questo questa mio tuo suo giorno notte anno vita mondo parola lavoro casa acqua luce vento albero verde blu rosso piccolo grande nuovo buono meglio mano dito tasto imparare scrivere leggere libro calma veloce città perché così"
    case .el: "α αν να ένα έναν είναι και το τα την τον ο η οι σε με δεν ναι όχι εγώ εσύ αυτό εμείς εσείς αυτοί που ποιος πώς πότε για χωρίς πολύ καλά όλα κάθε αυτός αυτή μου σου του μέρα νύχτα χρόνος ζωή κόσμος λέξη δουλειά σπίτι νερό φως άνεμος δέντρο πράσινο μπλε κόκκινο μικρό μεγάλο νέο καλό χέρι δάχτυλο πλήκτρο μάθημα γράφω διαβάζω βιβλίο ήρεμα γρήγορα"
    case .tr: "ne en anne anane ana tane yeni yine iyi bir bu şu o ben sen biz siz onlar ve ile için değil evet hayır kim nasıl zaman nerede her hep daha çok az güzel iyi gün gece yıl hayat dünya kelime iş ev su ışık rüzgar ağaç yeşil mavi kırmızı küçük büyük eski yeni el parmak tuş ders öğrenmek yazmak okumak kitap sakin hızlı doğru bugün yarın çocuk"
    case .mn: "а энэ тэр нэг нэр нар гэр эр хүн би чи та бид тэд байна бол юм мөн биш үгүй тийм сайн өдөр шөнө жил амьдрал дэлхий үг ажил ус гэрэл салхи мод ногоон хөх улаан жижиг том шинэ хуучин гар хуруу товч хичээл сурах бичих унших ном тайван хурдан зөв өнөөдөр маргааш хүүхэд монгол хэл үүл цас уул нуур зам хот найз эх орон баяр"
    } }
    public func letters(level: Int) -> String {
        let count = [5, 9, 14, 20, 26, 100][min(6, max(1, level)) - 1]
        return String(frequency.prefix(count))
    }
}
public enum LessonGenerator {
    public static func generate(preferences p: Preferences, level: Int, weaknesses: [String: KeyPerformance], supported: Set<Character>? = nil) -> String {
        var rng = SystemRandomNumberGenerator()
        return generate(preferences: p, level: level, weaknesses: weaknesses, supported: supported, using: &rng)
    }
    public static func generate<R: RandomNumberGenerator>(preferences p: Preferences, level: Int, weaknesses: [String: KeyPerformance], supported: Set<Character>? = nil, using rng: inout R) -> String {
        let alphabet = Set(p.language.letters(level: p.mode == .expert ? 6 : level))
        let allowed = supported.map { alphabet.intersection($0) } ?? alphabet
        let words = p.language.words.filter { word in word.allSatisfy { allowed.contains($0) } }
        let fallback = allowed.sorted().map(String.init)
        let pool = words.isEmpty ? fallback : words
        guard !pool.isEmpty else { return "" }
        let weights = pool.map { word in
            1.0 + word.reduce(0.0) { total, character in
                let stats = weaknesses[String(character), default: KeyPerformance()]
                return total + min(4, Double(stats.errors) / Double(max(1, stats.attempts)) * 6)
            }
        }
        let total = weights.reduce(0, +)
        var result: [String] = []
        for index in 0..<min(100, max(5, p.wordCount)) {
            var needle = Double.random(in: 0..<total, using: &rng)
            var selected = pool[0]
            for (word, weight) in zip(pool, weights) { needle -= weight; if needle < 0 { selected = word; break } }
            if p.capitals && index % 5 == 0 {
                let capital = selected.prefix(1).uppercased(with: Locale(identifier: p.language.rawValue)) + selected.dropFirst()
                if supported == nil || capital.allSatisfy({ supported!.contains($0) }) { selected = capital }
            }
            if p.numbers && index % 7 == 6 { selected = String(Int.random(in: 10...999, using: &rng)) }
            if p.punctuation && index % 4 == 3 {
                let symbols: [Character] = [",", ".", "!", "?", ":", ";", "-"]
                let available = symbols.filter { supported == nil || supported!.contains($0) }
                if let symbol = available.randomElement(using: &rng) { selected.append(symbol) }
            }
            result.append(selected)
        }
        return result.joined(separator: " ")
    }
}
