import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Query(sort: \MeltdownEvent.date, order: .reverse) private var allEvents: [MeltdownEvent]
    @State private var range: RangeOption = .month

    enum RangeOption: String, CaseIterable {
        case week = "7 días"; case month = "30 días"; case quarter = "90 días"
        var days: Int { switch self { case .week: return 7; case .month: return 30; case .quarter: return 90 } }
    }

    private var filtered:  [MeltdownEvent]    { DataService.recent(allEvents, days: range.days) }
    private var insights:  DataService.Insights { DataService.insights(from: filtered) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {

                    Picker("Rango", selection: $range) {
                        ForEach(RangeOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Total", value: "\(insights.totalEvents)", icon: "list.number", color: Theme.primary)
                        StatCard(title: "Duración promedio", value: "\(Int(insights.avgDuration)) min", icon: "clock", color: Theme.warning)
                        if let t = insights.mostCommonType {
                            StatCard(title: "Tipo frecuente", value: t.displayName, icon: "chart.bar", color: Theme.color(for: t))
                        }
                        if let h = insights.peakHour {
                            StatCard(title: "Hora pico", value: "\(h):00h", icon: "sun.and.horizon", color: Theme.danger)
                        }
                    }

                    // Type distribution
                    if !insights.typeDistribution.isEmpty {
                        VeraCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Distribución por tipo").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                                ForEach(MeltdownType.allCases) { type in
                                    let count = insights.typeDistribution[type] ?? 0
                                    let pct   = insights.totalEvents > 0 ? Double(count) / Double(insights.totalEvents) : 0
                                    HStack(spacing: 10) {
                                        Circle().fill(Theme.color(for: type)).frame(width: 10, height: 10)
                                        Text(type.displayName).font(Theme.bodyFont(14))
                                            .foregroundColor(Theme.textPrimary).frame(width: 130, alignment: .leading)
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4).fill(Theme.border).frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4).fill(Theme.color(for: type))
                                                    .frame(width: geo.size.width * pct, height: 8)
                                            }
                                        }.frame(height: 8)
                                        Text("\(Int(pct * 100))%").font(Theme.captionFont(12))
                                            .foregroundColor(Theme.textSecondary).frame(width: 34, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }

                    // Top triggers
                    if !insights.triggerDistribution.isEmpty {
                        VeraCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Desencadenantes más comunes").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                                let sorted = insights.triggerDistribution.sorted { $0.value > $1.value }.prefix(5)
                                ForEach(Array(sorted.enumerated()), id: \.offset) { idx, pair in
                                    HStack(spacing: 12) {
                                        Text("\(idx + 1)").font(Theme.captionFont(12)).foregroundColor(Theme.textTertiary).frame(width: 16)
                                        Image(systemName: pair.key.icon).foregroundColor(Theme.primary).frame(width: 20)
                                        Text(pair.key.displayName).font(Theme.bodyFont()).foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        Text("\(pair.value) veces").font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                    if idx < sorted.count - 1 { Divider() }
                                }
                            }
                        }
                    }

                    // Weekly bar chart
                    if !insights.weekdayDistribution.isEmpty {
                        VeraCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Patrón semanal").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                                let maxV = max(insights.weekdayDistribution.values.max() ?? 1, 1)
                                let days = ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"]
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(1...7, id: \.self) { wd in
                                        let n = insights.weekdayDistribution[wd] ?? 0
                                        VStack(spacing: 4) {
                                            Text("\(n)").font(Theme.captionFont(11))
                                                .foregroundColor(n > 0 ? Theme.primary : Theme.textTertiary)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(n > 0 ? Theme.primary : Theme.border)
                                                .frame(height: max(CGFloat(n) / CGFloat(maxV) * 60, 4))
                                            Text(days[wd - 1]).font(Theme.captionFont(11)).foregroundColor(Theme.textTertiary)
                                        }.frame(maxWidth: .infinity)
                                    }
                                }.frame(height: 90)
                            }
                        }
                    }

                    // Auto insights
                    if insights.totalEvents > 0 { AutoInsightsCard(insights: insights) }

                    if filtered.isEmpty {
                        VeraCard { EmptyState(icon: "chart.bar.xaxis", title: "Sin datos aún",
                                              subtitle: "Registra episodios para ver análisis y patrones.") }
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationTitle("Análisis")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - StatCard
private struct StatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(Theme.captionFont(12)).foregroundColor(Theme.textSecondary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
    }
}

// MARK: - AutoInsightsCard
private struct AutoInsightsCard: View {
    let insights: DataService.Insights

    private var bullets: [String] {
        var list: [String] = []
        if let t = insights.mostCommonType {
            let pct = insights.totalEvents > 0
                ? Int(Double(insights.typeDistribution[t] ?? 0) / Double(insights.totalEvents) * 100) : 0
            list.append("El \(pct)% de los episodios son de tipo '\(t.displayName)'")
        }
        if let t = insights.mostCommonTrigger {
            list.append("'\(t.displayName)' es el desencadenante más frecuente")
        }
        if let h = insights.peakHour {
            let p = h < 12 ? "mañana" : h < 18 ? "tarde" : "noche"
            list.append("La mayoría ocurre por la \(p) (alrededor de las \(h)h)")
        }
        if insights.avgDuration > 0 {
            list.append("Duración promedio: \(Int(insights.avgDuration)) minutos por episodio")
        }
        return list
    }

    var body: some View {
        VeraCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundColor(Theme.primary)
                    Text("Insights automáticos").font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                }
                ForEach(bullets, id: \.self) { b in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill").foregroundColor(Theme.primaryMid).font(.system(size: 14)).padding(.top, 1)
                        Text(b).font(Theme.bodyFont(14)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }
}
#Preview{
    AnalysisView()
}
