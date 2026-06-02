import Foundation
import NaturalLanguage

// MARK: - MLService
/// Classifies meltdown text using Natural Language Framework (lemmatization +
/// word embeddings). When a trained .mlmodel is compiled into the bundle,
/// it is loaded as an NLModel and used first for highest accuracy.
final class MLService {
    static let shared = MLService()

    private var nlModel:  NLModel?
    private let tagger  = NLTagger(tagSchemes: [.lemma, .tokenType])
    private let embedder: NLEmbedding? = NLEmbedding.wordEmbedding(for: .spanish)

    private init() {
        // Load CoreML model if compiled bundle exists (MeltdownClassifier.mlmodelc)
        if let url   = Bundle.main.url(forResource: "MeltdownClassifier", withExtension: "mlmodelc"),
           let model = try? NLModel(contentsOf: url) {
            self.nlModel = model
        }
    }

    // MARK: Public
    func classify(text: String) -> MeltdownType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .sobreestimulacion }

        // 1. CoreML-backed NLModel (highest accuracy)
        if let nlModel,
           let label = nlModel.predictedLabel(for: trimmed),
           let type  = MeltdownType(rawValue: label) {
            return type
        }

        // 2. NL-enhanced fallback: lemmatization + semantic similarity
        return classifyWithNL(trimmed)
    }

    // MARK: Private — NL pipeline
    private func classifyWithNL(_ text: String) -> MeltdownType {
        // Language detection
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let lang = recognizer.dominantLanguage ?? .spanish

        let lemmas = extractLemmas(from: text, language: lang)
        let lower  = text.lowercased()

        var scores: [MeltdownType: Double] = [:]
        for type in MeltdownType.allCases {
            let kw  = Double(keywordScore(lower, lemmas, for: type))
            let sem = semanticScore(lemmas, for: type)
            scores[type] = kw + sem * 1.5          // semantic weighted higher
        }
        return scores.max(by: { $0.value < $1.value })?.key ?? .sobreestimulacion
    }

    /// Extract lemmas using NLTagger (lloraba → llorar, ruidos → ruido, etc.)
    private func extractLemmas(from text: String, language: NLLanguage) -> [String] {
        tagger.string = text
        tagger.setLanguage(language, range: text.startIndex..<text.endIndex)

        var lemmas: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lemma,
                             options: options) { tag, range in
            let word = tag?.rawValue ?? String(text[range])
            lemmas.append(word.lowercased())
            return true
        }
        return lemmas
    }

    /// Keyword hit count against both raw text and lemmatized tokens.
    private func keywordScore(_ raw: String, _ lemmas: [String], for type: MeltdownType) -> Int {
        let joined = lemmas.joined(separator: " ")
        return keywords(for: type).reduce(0) {
            $0 + ((raw.contains($1) || joined.contains($1)) ? 1 : 0)
        }
    }

    /// Average cosine similarity between input lemmas and type anchor words.
    private func semanticScore(_ lemmas: [String], for type: MeltdownType) -> Double {
        guard let embedder else { return 0 }
        let anchors = semanticAnchors(for: type)
        var total = 0.0; var count = 0
        for lemma in lemmas {
            for anchor in anchors {
                let dist = embedder.distance(between: lemma, and: anchor)
                total += max(0, 1.0 - dist)   // distance → similarity
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : 0
    }

    private func keywords(for type: MeltdownType) -> [String] {
        switch type {
        case .sobreestimulacion:
            return ["ruido","sonido","luces","luz","olor","tacto","sabor","multitud","gente",
                    "música","sirena","brillante","fuerte","oídos","sensorial","secador",
                    "aspiradora","estimulación","parpadear","textura","destello"]
        case .frustracion:
            return ["frustración","frustrar","quería","quiero","obtener","conseguir",
                    "entender","comunicar","quitaron","dijimos","rabieta","enojo","enojar",
                    "negar","negamos","impedir","no pudo","no podía","no quiso"]
        case .cansancio:
            return ["cansado","agotado","sueño","dormido","durmió","no durmió","tarde","noche",
                    "cansancio","fatiga","somnoliento","dormir","descanso","bostezo","despertar"]
        case .cambioRutina:
            return ["cambio","rutina","diferente","nuevo","cancelaron","faltó","no estaba",
                    "inesperado","cambiaron","horario","sustituto","otra puerta","otra ruta",
                    "sorpresa","imprevisto","modificación"]
        }
    }

    private func semanticAnchors(for type: MeltdownType) -> [String] {
        switch type {
        case .sobreestimulacion: return ["ruido","luz","sensación","estímulo"]
        case .frustracion:       return ["frustración","enojo","rabia","bloqueo"]
        case .cansancio:         return ["cansancio","sueño","agotamiento","fatiga"]
        case .cambioRutina:      return ["cambio","rutina","sorpresa","imprevisto"]
        }
    }
}

// MARK: - SuggestionService
final class SuggestionService {
    static let shared = SuggestionService()
    private init() {}

    struct Suggestion: Identifiable {
        let id   = UUID()
        let text: String
        let icon: String
    }

    func suggestions(for type: MeltdownType, profile: ChildProfile? = nil) -> [Suggestion] {
        var base = base(for: type)
        if let profile {
            let learned = profile.effectiveStrategies
                .compactMap { CalmingStrategy(rawValue: $0) }
                .prefix(2).map { Suggestion(text: $0.displayName, icon: $0.icon) }
            base = Array(learned) + base
        }
        return Array(base.prefix(5))
    }

    func crisisSteps(for type: MeltdownType) -> [(title: String, steps: [String])] {
        switch type {
        case .sobreestimulacion:
            return [
                ("Dar espacio inmediato", ["Aléjate o mantén distancia",
                                           "No toques sin permiso",
                                           "Habla lo menos posible"]),
                ("Reducir estímulos",     ["Baja el volumen o las luces",
                                           "Cierra puertas o ventanas",
                                           "Retira personas del área"]),
                ("Apoyo sensorial",       ["Ofrece auriculares o tapones",
                                           "Manta con peso si le gusta",
                                           "Su objeto de confort conocido"]),
                ("Monitorear y esperar",  ["Permanece cerca sin presionar",
                                           "Observa señales de calma",
                                           "Permite el tiempo necesario"])
            ]
        case .frustracion:
            return [
                ("Validar y dar espacio", ["Di: entiendo que estás molesto",
                                           "No argumentes ni expliques aún",
                                           "Baja tu propio tono de voz"]),
                ("Reducir presión",       ["Retira demandas inmediatas",
                                           "Elimina audiencia si la hay",
                                           "Simplifica el entorno"]),
                ("Ofrecer alternativa",   ["Propón una actividad simple",
                                           "Usa apoyo visual si es posible",
                                           "Actúa con calma y lentitud"]),
                ("Monitorear y esperar",  ["Permanece cerca sin presionar",
                                           "Observa señales de calma",
                                           "Permite el tiempo necesario"])
            ]
        case .cansancio:
            return [
                ("Reducir demandas",      ["Cancela actividades pendientes",
                                           "No exijas respuestas o tareas",
                                           "Habla con frases cortas"]),
                ("Ambiente de calma",     ["Lleva a lugar tranquilo y oscuro",
                                           "Ofrece manta o peluche favorito",
                                           "Pon música suave o silencio"]),
                ("Ofrecer descanso",      ["Permite tumbarse o sentarse",
                                           "No impongas sueño, solo descanso",
                                           "Acompaña sin hablar"]),
                ("Monitorear y esperar",  ["Permanece cerca sin presionar",
                                           "Observa señales de calma",
                                           "Permite el tiempo necesario"])
            ]
        case .cambioRutina:
            return [
                ("Validar y nombrar",     ["Di: sé que esto es diferente",
                                           "No minimices la reacción",
                                           "Escucha sin interrumpir"]),
                ("Dar predecibilidad",    ["Explica qué pasará ahora",
                                           "Usa soporte visual si es posible",
                                           "Mantén tu tono estable"]),
                ("Elemento familiar",     ["Ofrece objeto de confort",
                                           "Introduce un ritual conocido",
                                           "Conecta con algo predecible"]),
                ("Monitorear y esperar",  ["Permanece cerca sin presionar",
                                           "Observa señales de calma",
                                           "Permite el tiempo necesario"])
            ]
        }
    }

    private func base(for type: MeltdownType) -> [Suggestion] {
        switch type {
        case .sobreestimulacion:
            return [Suggestion(text: "Mover a un espacio tranquilo",         icon: "house.fill"),
                    Suggestion(text: "Reducir estímulos del entorno",        icon: "speaker.slash"),
                    Suggestion(text: "Ofrecer auriculares con cancelación",  icon: "headphones"),
                    Suggestion(text: "Bajar la iluminación",                 icon: "moon.fill"),
                    Suggestion(text: "Hablar con voz suave y pausada",       icon: "waveform")]
        case .frustracion:
            return [Suggestion(text: "Validar sus emociones verbalmente",    icon: "heart.fill"),
                    Suggestion(text: "Ofrecer una alternativa simple",       icon: "arrow.triangle.2.circlepath"),
                    Suggestion(text: "Dar tiempo y espacio sin presionar",   icon: "clock"),
                    Suggestion(text: "Usar apoyo visual o pictogramas",      icon: "photo"),
                    Suggestion(text: "Ayudar a completar la tarea juntos",   icon: "hands.sparkles")]
        case .cansancio:
            return [Suggestion(text: "Llevar a lugar cómodo a descansar",    icon: "bed.double.fill"),
                    Suggestion(text: "Ofrecer manta o peluche favorito",     icon: "teddybear"),
                    Suggestion(text: "Reducir demandas al mínimo",           icon: "minus.circle"),
                    Suggestion(text: "Poner música suave o silencio total",  icon: "music.note"),
                    Suggestion(text: "Permitir actividad de bajo esfuerzo",  icon: "leaf.fill")]
        case .cambioRutina:
            return [Suggestion(text: "Explicar el cambio con calma",         icon: "text.bubble"),
                    Suggestion(text: "Mostrar la nueva rutina visualmente",  icon: "list.bullet.clipboard"),
                    Suggestion(text: "Ofrecer un objeto de transición",      icon: "teddybear"),
                    Suggestion(text: "Mantener elementos predecibles",       icon: "checkmark.shield"),
                    Suggestion(text: "Anticipar próximos cambios con tiempo",icon: "calendar.badge.clock")]
        }
    }
}

// MARK: - DataService
struct DataService {

    struct Insights {
        var totalEvents:         Int
        var mostCommonType:      MeltdownType?
        var mostCommonTrigger:   Trigger?
        var peakHour:            Int?
        var avgDuration:         Double
        var typeDistribution:    [MeltdownType: Int]
        var triggerDistribution: [Trigger: Int]
        var weekdayDistribution: [Int: Int]
    }

    static func insights(from events: [MeltdownEvent]) -> Insights {
        var typeCount:    [MeltdownType: Int] = [:]
        var triggerCount: [Trigger: Int]      = [:]
        var hourCount:    [Int: Int]           = [:]
        var weekdayCount: [Int: Int]           = [:]
        var totalDuration = 0

        for e in events {
            typeCount[e.type, default: 0] += 1
            for t in e.triggerEnums { triggerCount[t, default: 0] += 1 }
            hourCount[Calendar.current.component(.hour,    from: e.date), default: 0] += 1
            weekdayCount[Calendar.current.component(.weekday, from: e.date), default: 0] += 1
            totalDuration += e.durationMinutes
        }

        return Insights(
            totalEvents:         events.count,
            mostCommonType:      typeCount.max(by:    { $0.value < $1.value })?.key,
            mostCommonTrigger:   triggerCount.max(by: { $0.value < $1.value })?.key,
            peakHour:            hourCount.max(by:    { $0.value < $1.value })?.key,
            avgDuration:         events.isEmpty ? 0 : Double(totalDuration) / Double(events.count),
            typeDistribution:    typeCount,
            triggerDistribution: triggerCount,
            weekdayDistribution: weekdayCount
        )
    }

    static func events(on date: Date, from all: [MeltdownEvent]) -> [MeltdownEvent] {
        // Use the device's current calendar and timezone for day comparison
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return all.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    static func recent(_ events: [MeltdownEvent], days: Int = 30) -> [MeltdownEvent] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return events.filter { $0.date >= cutoff }
    }
}
