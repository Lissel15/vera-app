import SwiftUI
import SwiftData

struct TrackView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ChildProfile]

    @State private var date               = Date()
    @State private var selectedTriggers:  Set<Trigger>         = []
    @State private var selectedBehaviors: Set<Behavior>        = []
    @State private var selectedCalming:   Set<CalmingStrategy> = []
    @State private var selectedIntensity: Intensity            = .moderado
    @State private var duration:          Double               = 10
    @State private var notes              = ""
    @State private var detectedType:      MeltdownType?        = nil
    @State private var isSaved            = false

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {

                    // Date & time row
                    HStack(spacing: 10) {
                        Label(date.formatted(.dateTime.day().month().year()), systemImage: "calendar")
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))

                        Label(date.formatted(.dateTime.hour().minute()), systemImage: "clock")
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))

                        Spacer()
                        DatePicker("", selection: $date).labelsHidden().tint(Theme.primary)
                    }

                    // Triggers
                    chipSection(title: "Desencadenantes", color: Theme.warning) {
                        ForEach(Trigger.allCases) { t in
                            SelectableChip(icon: t.icon, label: t.displayName,
                                           isSelected: selectedTriggers.contains(t)) {
                                toggle(&selectedTriggers, t); updateType()
                            }
                        }
                    }

                    // Behaviors
                    chipSection(title: "Durante el meltdown", color: Theme.danger) {
                        ForEach(Behavior.allCases) { b in
                            SelectableChip(icon: b.icon, label: b.displayName,
                                           isSelected: selectedBehaviors.contains(b)) {
                                toggle(&selectedBehaviors, b)
                            }
                        }
                    }

                    // Calming
                    chipSection(title: "Lo que calmó", color: Theme.primary) {
                        ForEach(CalmingStrategy.allCases) { s in
                            SelectableChip(icon: s.icon, label: s.displayName,
                                           isSelected: selectedCalming.contains(s)) {
                                toggle(&selectedCalming, s)
                            }
                        }
                    }

                    // Intensity
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "Intensidad", color: Theme.textPrimary)
                        HStack(spacing: 8) {
                            ForEach(Intensity.allCases) { level in
                                Button { selectedIntensity = level } label: {
                                    Text(level.displayName)
                                        .font(Theme.captionFont())
                                        .foregroundColor(selectedIntensity == level ? .white : Theme.textSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selectedIntensity == level ? Theme.danger : Theme.surface)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(title: "Duración", color: Theme.textPrimary)
                            Spacer()
                            Text("\(Int(duration)) min").font(Theme.headlineFont()).foregroundColor(Theme.primary)
                        }
                        Slider(value: $duration, in: 1...120, step: 1).tint(Theme.primary)
                    }

                    // ML preview
                    if let type = detectedType {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles").foregroundColor(Theme.primary)
                            Text("Tipo detectado:").font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                            TypeBadge(type: type)
                        }
                        .padding(12).background(Theme.primaryLight)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notas adicionales").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .font(Theme.bodyFont())
                                .frame(minHeight: 100)
                                .padding(10)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                            if notes.isEmpty {
                                Text("Describe con más detalle lo que pasó ese día...")
                                    .font(Theme.bodyFont()).foregroundColor(Theme.textTertiary)
                                    .padding(18).allowsHitTesting(false)
                            }
                        }
                        HStack {
                            Spacer()
                            Text("\(notes.count) / 500")
                                .font(Theme.captionFont(11)).foregroundColor(Theme.textTertiary)
                        }
                    }

                    PrimaryButton(title: isSaved ? "¡Guardado!" : "Guardar",
                                  icon: isSaved ? "checkmark" : nil) { save() }
                        .padding(.bottom, Theme.spacingL)
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationTitle("Registrar meltdown")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Helpers
    @ViewBuilder
    private func chipSection<Content: View>(title: String, color: Color, @ViewBuilder chips: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: title, color: color)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) { chips() }.padding(.horizontal, 2)
            }
        }
    }

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ item: T) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }

    private func updateType() {
        guard !selectedTriggers.isEmpty else { detectedType = nil; return }
        detectedType = MLService.shared.classify(text: selectedTriggers.map(\.displayName).joined(separator: " "))
    }

    private func save() {
        let type = detectedType ?? MLService.shared.classify(text: notes)
        print("[Vera] Guardando evento tipo: \(type.rawValue)")
        let event = MeltdownEvent(
            date: date,
            triggers: Array(selectedTriggers),
            behaviors: Array(selectedBehaviors),
            calmingStrategies: Array(selectedCalming),
            type: type,
            intensity: selectedIntensity,
            durationMinutes: Int(duration),
            notes: notes,
            childProfileID: profile?.id
        )
        context.insert(event)
        do {
            try context.save()
            print("[Vera] ✅ MeltdownEvent guardado: \(event.typeRaw) — \(event.date)")
        } catch {
            print("[Vera] ❌ Error al guardar: \(error)")
        }

        withAnimation { isSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { resetForm() }
    }

    private func resetForm() {
        selectedTriggers = []; selectedBehaviors = []; selectedCalming = []
        selectedIntensity = .moderado; duration = 10; notes = ""
        date = .now; detectedType = nil; isSaved = false
    }
}
#Preview{
    TrackView()
}
