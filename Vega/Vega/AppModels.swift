import SwiftData
import Foundation
 
// MARK: - MeltdownEvent
@Model
final class MeltdownEvent {
    var id:                UUID
    var date:              Date
    var triggers:          [String]
    var behaviors:         [String]
    var calmingStrategies: [String]
    var typeRaw:           String
    var intensityRaw:      Int
    var durationMinutes:   Int
    var notes:             String
    var childProfileID:    UUID?
 
    init(
        date:              Date            = .now,
        triggers:          [Trigger]       = [],
        behaviors:         [Behavior]      = [],
        calmingStrategies: [CalmingStrategy] = [],
        type:              MeltdownType    = .sobreestimulacion,
        intensity:         Intensity       = .moderado,
        durationMinutes:   Int             = 10,
        notes:             String          = "",
        childProfileID:    UUID?           = nil
    ) {
        self.id                 = UUID()
        self.date               = date
        self.triggers           = triggers.map(\.rawValue)
        self.behaviors          = behaviors.map(\.rawValue)
        self.calmingStrategies  = calmingStrategies.map(\.rawValue)
        self.typeRaw            = type.rawValue
        self.intensityRaw       = intensity.rawValue
        self.durationMinutes    = durationMinutes
        self.notes              = notes
        self.childProfileID     = childProfileID
    }
 
    // Computed helpers
    var type: MeltdownType {
        MeltdownType(rawValue: typeRaw) ?? .sobreestimulacion
    }
    var intensity: Intensity {
        Intensity(rawValue: intensityRaw) ?? .moderado
    }
    var triggerEnums: [Trigger] {
        triggers.compactMap { Trigger(rawValue: $0) }
    }
    var behaviorEnums: [Behavior] {
        behaviors.compactMap { Behavior(rawValue: $0) }
    }
    var calmingEnums: [CalmingStrategy] {
        calmingStrategies.compactMap { CalmingStrategy(rawValue: $0) }
    }
}
 
// MARK: - ChildProfile
@Model
final class ChildProfile {
    var id:                  UUID
    var name:                String
    var age:                 Int
    var knownTriggers:       [String]
    var effectiveStrategies: [String]
    var notes:               String
    var createdAt:           Date
 
    init(name: String = "", age: Int = 5) {
        self.id                  = UUID()
        self.name                = name
        self.age                 = age
        self.knownTriggers       = []
        self.effectiveStrategies = []
        self.notes               = ""
        self.createdAt           = .now
    }
}
 
// MARK: - LearnedStrategy
@Model
final class LearnedStrategy {
    var id:           UUID
    var triggerRaw:   String
    var strategyRaw:  String
    var successCount: Int
    var lastUsed:     Date
 
    init(trigger: Trigger, strategy: CalmingStrategy) {
        self.id           = UUID()
        self.triggerRaw   = trigger.rawValue
        self.strategyRaw  = strategy.rawValue
        self.successCount = 1
        self.lastUsed     = .now
    }
 
    var trigger:  Trigger?          { Trigger(rawValue: triggerRaw) }
    var strategy: CalmingStrategy?  { CalmingStrategy(rawValue: strategyRaw) }
}
 
