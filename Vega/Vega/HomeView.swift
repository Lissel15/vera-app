import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \MeltdownEvent.date, order: .reverse) private var events: [MeltdownEvent]
    @Query private var profiles: [ChildProfile]
    @State private var showCrisis = false

    private var profile: ChildProfile? { profiles.first }
    private var insights: DataService.Insights { DataService.insights(from: events) }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 6..<12:  return "Buenos días"
        case 12..<19: return "Buenas tardes"
        default:      return "Buenas noches"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(Theme.titleFont(30))
                            .foregroundColor(Theme.textBlue)
                        Text(profile.map { "¿Cómo va \($0.name) hoy?" } ?? "¿Cómo va todo hoy?")
                            .font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
                    }

                    // Crisis button
                    Button { showCrisis = true } label: {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Color.red, Color.red.opacity(1), Color.red.opacity(0.9), Color.red.opacity(0.6), Color.red.opacity(0.15)],
                                    center: .center, startRadius: 0, endRadius: 130
                                ))
                                .frame (width: 240, height: 240)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60, weight: .semibold))
                                .foregroundColor(Color.white)
                                
                        }
                        
                    }
                    .frame(maxWidth: .infinity).buttonStyle(.plain)
                    

                    // Quick insight — show whenever there are events
                    if !events.isEmpty {
                        QuickInsightCard(insights: insights, eventCount: events.count)
                    }

                    // What helps
                    if let trigger = insights.mostCommonTrigger {
                        WhatHelpsCard(trigger: trigger, profile: profile)
                    }

                    // Recent events
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Registros recientes")
                            .font(Theme.headlineFont())
                            

                        if events.isEmpty {
                            VeraCard {
                                EmptyState(
                                    icon: "doc.text.magnifyingglass",
                                    title: "Sin registros aún",
                                    subtitle: "Usa el botón de crisis o la pestaña Seguimiento."
                                )
                                
                            }
                        } else {
                            VeraCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(events.prefix(5))) { event in
                                        EventRow(event: event)
                                        if event.id != events.prefix(5).last?.id {
                                            Divider().padding(.vertical, 4)
                                        }
                                    }
                                }

                            }

                        }
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCrisis) { CrisisModeView() }
        }
    }
}

// MARK: - QuickInsightCard
private struct QuickInsightCard: View {
    let insights: DataService.Insights
    let eventCount: Int

    var body: some View {
        BlueCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles").foregroundColor(Theme.primary).font(.system(size: 18))
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumen").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)

                    HStack {
                        Text("Total de episodios:").font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                        Text("\(eventCount)").font(Theme.headlineFont(15)).foregroundColor(Theme.primary)
                    }

                    if let trigger = insights.mostCommonTrigger {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Desencadenante más común")
                                .font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                            Text(trigger.displayName)
                                .font(Theme.headlineFont(17)).foregroundColor(Theme.primary)
                        }
                    }
                    if let type = insights.mostCommonType {
                        HStack {
                            Text("Tipo frecuente:").font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                            TypeBadge(type: type)
                        }
                    }
                    if let hour = insights.peakHour {
                        Text("Hora pico: \(hour):00h")
                            .font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - WhatHelpsCard
private struct WhatHelpsCard: View {
    let trigger: Trigger
    let profile: ChildProfile?

    private var suggestions: [SuggestionService.Suggestion] {
        let type: MeltdownType = [.sonido, .olor, .tacto, .visual, .sabor].contains(trigger)
            ? .sobreestimulacion : .cambioRutina
        return SuggestionService.shared.suggestions(for: type, profile: profile)
    }

    var body: some View {
        VeraCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "heart").foregroundColor(Theme.danger)
                    Text("Qué Ayuda").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                }
                Text("Estrategias y objetos de confort que pueden ser de ayuda")
                    .font(Theme.bodyFont(14)).foregroundColor(Theme.textSecondary)
                ForEach(suggestions) { s in
                    HStack(spacing: 12) {
                        Circle().fill(Theme.primaryLight).frame(width: 8, height: 8)
                        Text(s.text).font(Theme.bodyFont(15)).foregroundColor(Theme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
                }
            }
        }
    }
}

#Preview{
    HomeView()
}
