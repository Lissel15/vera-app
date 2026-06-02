import SwiftUI
import SwiftData

// MARK: - ProfileView
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ChildProfile]
    @Query(sort: \MeltdownEvent.date, order: .reverse) private var events: [MeltdownEvent]
    @State private var showSetup = false

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {

                    // Profile header
                    if let p = profile {
                        profileHeader(p)
                    } else {
                        newProfilePrompt
                    }

                    // Stats
                    VeraCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Resumen general").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                            HStack(spacing: 0) {
                                StatItem(label: "Total",       value: "\(events.count)")
                                Divider().frame(height: 40)
                                StatItem(label: "Este mes",    value: "\(DataService.recent(events, days: 30).count)")
                                Divider().frame(height: 40)
                                StatItem(label: "Esta semana", value: "\(DataService.recent(events, days: 7).count)")
                            }
                        }
                    }

                    // Known triggers
                    if let p = profile, !p.knownTriggers.isEmpty {
                        VeraCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Desencadenantes conocidos").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                                FlowLayout(spacing: 8) {
                                    ForEach(p.knownTriggers.compactMap { Trigger(rawValue: $0) }) { t in
                                        Label(t.displayName, systemImage: t.icon)
                                            .font(Theme.captionFont())
                                            .foregroundColor(Theme.textSecondary)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(Theme.surface)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Effective strategies
                    if let p = profile, !p.effectiveStrategies.isEmpty {
                        VeraCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Lo que funciona").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                                    Image(systemName: "sparkles").foregroundColor(Theme.primary)
                                }
                                ForEach(p.effectiveStrategies.prefix(5).compactMap { CalmingStrategy(rawValue: $0) }) { s in
                                    HStack(spacing: 12) {
                                        Image(systemName: s.icon).foregroundColor(Theme.success).frame(width: 20)
                                        Text(s.displayName).font(Theme.bodyFont()).foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                        }
                    }

                    // App info
                    VeraCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acerca de Vera").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                            InfoRow(icon: "brain.head.profile",  label: "Clasificación con Core ML")
                            InfoRow(icon: "mic.fill",            label: "Dictado con Speech Framework")
                            InfoRow(icon: "speaker.wave.2.fill", label: "Respuesta por voz con AVFoundation")
                            InfoRow(icon: "lock.shield.fill",    label: "Datos almacenados localmente")
                            Text("Versión 1.0 · Vera")
                                .font(Theme.captionFont(12)).foregroundColor(Theme.textTertiary).padding(.top, 4)
                        }
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSetup) { ChildSetupView(existing: profile) }
        }
    }

    // MARK: Sub-views
    @ViewBuilder
    private func profileHeader(_ p: ChildProfile) -> some View {
        VeraCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.primaryLight).frame(width: 64, height: 64)
                    Text(String(p.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(Theme.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.name).font(Theme.headlineFont(18)).foregroundColor(Theme.textPrimary)
                    Text("\(p.age) años").font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
                    if !p.notes.isEmpty {
                        Text(p.notes).font(Theme.captionFont()).foregroundColor(Theme.textTertiary).lineLimit(2)
                    }
                }
                Spacer()
                Button { showSetup = true } label: {
                    Image(systemName: "pencil.circle.fill").font(.system(size: 28)).foregroundColor(Theme.primary)
                }.buttonStyle(.plain)
            }
        }
    }

    private var newProfilePrompt: some View {
        VeraCard {
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus").font(.system(size: 40)).foregroundColor(Theme.primary)
                Text("Configura el perfil").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                Text("Agrega los datos del niño para personalizar las sugerencias")
                    .font(Theme.bodyFont()).foregroundColor(Theme.textSecondary).multilineTextAlignment(.center)
                PrimaryButton(title: "Crear perfil", icon: "plus") { showSetup = true }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - ChildSetupView
struct ChildSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existing: ChildProfile?

    @State private var name       = ""
    @State private var age        = 5
    @State private var notes      = ""
    @State private var triggers:  Set<Trigger>         = []
    @State private var strategies: Set<CalmingStrategy> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {

                    // Name
                    fieldSection("Nombre del niño") {
                        TextField("Nombre", text: $name)
                            .font(Theme.bodyFont()).padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                    }

                    // Age
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Edad").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(age) años").font(Theme.headlineFont()).foregroundColor(Theme.primary)
                        }
                        Slider(value: Binding(get: { Double(age) }, set: { age = Int($0) }),
                               in: 2...18, step: 1).tint(Theme.primary)
                    }

                    // Known triggers
                    fieldSection("Desencadenantes conocidos",
                                 subtitle: "Los que suelen provocar episodios") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                            ForEach(Trigger.allCases) { t in
                                SelectableChip(icon: t.icon, label: t.displayName, isSelected: triggers.contains(t)) {
                                    if triggers.contains(t) { triggers.remove(t) } else { triggers.insert(t) }
                                }
                            }
                        }
                    }

                    // Effective strategies
                    fieldSection("Estrategias que funcionan",
                                 subtitle: "Lo que ha calmado antes al niño") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                            ForEach(CalmingStrategy.allCases) { s in
                                SelectableChip(icon: s.icon, label: s.displayName, isSelected: strategies.contains(s)) {
                                    if strategies.contains(s) { strategies.remove(s) } else { strategies.insert(s) }
                                }
                            }
                        }
                    }

                    // Notes
                    fieldSection("Notas adicionales") {
                        TextField("Diagnóstico, preferencias, contexto...", text: $notes, axis: .vertical)
                            .font(Theme.bodyFont()).lineLimit(3...5).padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                    }

                    PrimaryButton(title: existing == nil ? "Crear perfil" : "Guardar cambios",
                                  icon: "checkmark") { save() }
                        .padding(.bottom, Theme.spacingL)
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationTitle(existing == nil ? "Nuevo perfil" : "Editar perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
            if let sub = subtitle {
                Text(sub).font(Theme.bodyFont(14)).foregroundColor(Theme.textSecondary)
            }
            content()
        }
    }

    private func loadExisting() {
        guard let p = existing else { return }
        name       = p.name
        age        = p.age
        notes      = p.notes
        triggers   = Set(p.knownTriggers.compactMap       { Trigger(rawValue: $0) })
        strategies = Set(p.effectiveStrategies.compactMap { CalmingStrategy(rawValue: $0) })
    }

    private func save() {
        if let p = existing {
            p.name                = name
            p.age                 = age
            p.notes               = notes
            p.knownTriggers       = triggers.map(\.rawValue)
            p.effectiveStrategies = strategies.map(\.rawValue)
            try? context.save()
            print("[Vera] ✅ Perfil actualizado: \(name)")
        } else {
            let p = ChildProfile(name: name, age: age)
            p.notes               = notes
            p.knownTriggers       = triggers.map(\.rawValue)
            p.effectiveStrategies = strategies.map(\.rawValue)
            context.insert(p)
            try? context.save()
            print("[Vera] ✅ Perfil creado: \(name)")
        }
        dismiss()
    }
}

// MARK: - Helpers
private struct StatItem: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(Theme.textPrimary)
            Text(label).font(Theme.captionFont(12)).foregroundColor(Theme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}

private struct InfoRow: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.primary).frame(width: 20)
            Text(label).font(Theme.bodyFont(14)).foregroundColor(Theme.textPrimary)
        }
    }
}
