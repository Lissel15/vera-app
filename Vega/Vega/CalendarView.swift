import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \MeltdownEvent.date, order: .reverse) private var events: [MeltdownEvent]
    @State private var month:        Date  = .now
    @State private var selectedDate: Date? = nil

    private let cal = Calendar.current

    private var dayEvents: [MeltdownEvent] {
        guard let d = selectedDate else { return [] }
        return DataService.events(on: d, from: events)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingM) {

                    // Calendar card
                    VeraCard(padding: Theme.spacingM) {
                        VStack(spacing: 14) {
                            monthHeader
                            weekdayRow
                            dayGrid
                        }
                    }

                    // Selected day detail
                    if let selected = selectedDate {
                        dayDetailCard(date: selected)
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Color.white)
            .navigationTitle("Calendario")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hoy") { month = .now; selectedDate = .now }
                        .font(Theme.bodyFont()).foregroundColor(Theme.primary).bold()
                }
            }
        }
    }

    // MARK: Sub-views
    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-12) } label: { Image(systemName: "chevron.left.2").foregroundColor(Theme.textSecondary) }
            Button { shiftMonth(-1)  } label: { Image(systemName: "chevron.left").foregroundColor(Theme.textSecondary) }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
            Spacer()
            Button { shiftMonth(1)  } label: { Image(systemName: "chevron.right").foregroundColor(Theme.textSecondary) }
            Button { shiftMonth(12) } label: { Image(systemName: "chevron.right.2").foregroundColor(Theme.textSecondary) }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"], id: \.self) { d in
                Text(d).font(Theme.captionFont(12)).foregroundColor(Theme.textTertiary).frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(daysInMonth(), id: \.self) { optDate in
                if let d = optDate {
                    DayCell(
                        date: d,
                        isToday:    cal.isDateInToday(d),
                        isSelected: selectedDate.map { cal.isDate($0, inSameDayAs: d) } ?? false,
                        hasEvent:   !DataService.events(on: d, from: events).isEmpty
                    ) {
                        selectedDate = (selectedDate.map { cal.isDate($0, inSameDayAs: d) } == true) ? nil : d
                    }
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    @ViewBuilder
    private func dayDetailCard(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(Theme.headlineFont()).foregroundColor(Theme.textPrimary)
                Spacer()
                Button { selectedDate = nil } label: {
                    Image(systemName: "xmark").foregroundColor(Theme.textSecondary).padding(6)
                }
            }

            if dayEvents.isEmpty {
                Text("Sin episodios este día").font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
            } else {
                ForEach(dayEvents) { event in EventDetailCard(event: event) }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
    }

    // MARK: Helpers
    private func shiftMonth(_ v: Int) {
        let comp: Calendar.Component = abs(v) >= 12 ? .year : .month
        let amt = abs(v) >= 12 ? v / 12 : v
        month = cal.date(byAdding: comp, value: amt, to: month) ?? month
    }

    private func daysInMonth() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: month))
        else { return [] }
        let offset = cal.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        return days
    }
}

// MARK: - DayCell
private struct DayCell: View {
    let date: Date; let isToday: Bool; let isSelected: Bool; let hasEvent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white : isToday ? Theme.primary : Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(
                        Group {
                            if isSelected    { Circle().fill(Theme.primary) }
                            else if isToday  { Circle().stroke(Theme.primary, lineWidth: 1.5) }
                            else             { Circle().fill(Color.clear) }
                        }
                    )
                Circle()
                    .fill(hasEvent ? (isSelected ? Color.white.opacity(0.8) : Theme.primary) : Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EventDetailCard
private struct EventDetailCard: View {
    let event: MeltdownEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.date, style: .time)
                .font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TypeBadge(type: event.type)
                    Spacer()
                    Text("\(event.durationMinutes) min")
                        .font(Theme.captionFont()).foregroundColor(Theme.textTertiary)
                }
                if !event.notes.isEmpty {
                    Text(event.notes).font(Theme.bodyFont(14)).foregroundColor(Theme.textSecondary).lineLimit(2)
                }
                if !event.triggerEnums.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(event.triggerEnums.prefix(3)) { t in
                            Label(t.displayName, systemImage: t.icon)
                                .font(Theme.captionFont(11)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerS).stroke(Theme.border, lineWidth: 1))
    }
}

#Preview{
    CalendarView()
}
