import Foundation

// MARK: - MeltdownType
enum MeltdownType: String, Codable, CaseIterable, Identifiable {
    case sobreestimulacion = "sobreestimulacion"
    case frustracion       = "frustracion"
    case cansancio         = "cansancio"
    case cambioRutina      = "cambio_rutina"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sobreestimulacion: return "Sobreestimulación"
        case .frustracion:       return "Frustración"
        case .cansancio:         return "Cansancio"
        case .cambioRutina:      return "Cambio de rutina"
        }
    }

    var icon: String {
        switch self {
        case .sobreestimulacion: return "speaker.wave.3"
        case .frustracion:       return "cloud.bolt"
        case .cansancio:         return "powersleep"
        case .cambioRutina:      return "repeat.circle"
        }
    }
}

// MARK: - Trigger
enum Trigger: String, Codable, CaseIterable, Identifiable {
    case sonido, olor, sabor, tacto, visual, hambre, calor, multitud, cambio, espera

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .sonido:   return "speaker.wave.2"
        case .olor:     return "wind"
        case .sabor:    return "drop.triangle"
        case .tacto:    return "hand.raised"
        case .visual:   return "eye"
        case .hambre:   return "fork.knife"
        case .calor:    return "thermometer.sun"
        case .multitud: return "person.3"
        case .cambio:   return "arrow.triangle.2.circlepath"
        case .espera:   return "clock"
        }
    }
}

// MARK: - Behavior
enum Behavior: String, Codable, CaseIterable, Identifiable {
    case llorar, gritar, golpear, huir, conductaRepetitiva, taparseOidos, tirarCosas, morder

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .llorar:             return "Llorar"
        case .gritar:             return "Gritar"
        case .golpear:            return "Golpear"
        case .huir:               return "Huir"
        case .conductaRepetitiva: return "Conducta repetitiva"
        case .taparseOidos:       return "Taparse oídos"
        case .tirarCosas:         return "Tirar cosas"
        case .morder:             return "Morder"
        }
    }

    var icon: String {
        switch self {
        case .llorar:             return "drop.fill"
        case .gritar:             return "megaphone"
        case .golpear:            return "hand.raised.fingers.spread"
        case .huir:               return "figure.run"
        case .conductaRepetitiva: return "arrow.triangle.2.circlepath"
        case .taparseOidos:       return "ear.trianglebadge.exclamationmark"
        case .tirarCosas:         return "arrow.up.right"
        case .morder:             return "mouth"
        }
    }
}

// MARK: - CalmingStrategy
enum CalmingStrategy: String, Codable, CaseIterable, Identifiable {
    case agua, tacto, sonido, olfato, espacio, oscuridad, presionProfunda, objetoConfort, musica, respiracion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .agua:            return "Agua"
        case .tacto:           return "Tacto suave"
        case .sonido:          return "Sonido calmante"
        case .olfato:          return "Aromaterapia"
        case .espacio:         return "Espacio tranquilo"
        case .oscuridad:       return "Oscuridad"
        case .presionProfunda: return "Presión profunda"
        case .objetoConfort:   return "Objeto de confort"
        case .musica:          return "Música suave"
        case .respiracion:     return "Respiración"
        }
    }

    var icon: String {
        switch self {
        case .agua:            return "drop"
        case .tacto:           return "hand.raised"
        case .sonido:          return "headphones"
        case .olfato:          return "leaf"
        case .espacio:         return "house"
        case .oscuridad:       return "moon"
        case .presionProfunda: return "figure.child"
        case .objetoConfort:   return "teddybear"
        case .musica:          return "music.note"
        case .respiracion:     return "wind"
        }
    }
}

// MARK: - Intensity
enum Intensity: Int, Codable, CaseIterable, Identifiable {
    case leve = 1, moderado = 2, intenso = 3, severo = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .leve:     return "Leve"
        case .moderado: return "Moderado"
        case .intenso:  return "Intenso"
        case .severo:   return "Severo"
        }
    }
}

