import SwiftUI

// MARK: - VeraCard
struct VeraCard<Content: View>: View {
    var padding: CGFloat = Theme.spacingM
    var background: Color = Theme.surface
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.blue, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct BlueCard<Content: View>: View {
    var padding: CGFloat = Theme.spacingM
    var background: Color = Theme.blueligth
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Theme.blueligth)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.blue, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - PrimaryButton
struct PrimaryButton: View {
    let title:     String
    var icon:      String? = nil
    var isLoading: Bool    = false
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title).font(Theme.headlineFont())
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
        }
        .disabled(isLoading)
    }
}

// MARK: - SecondaryButton
struct SecondaryButton: View {
    let title:  String
    var icon:   String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(Theme.headlineFont())
            }
            .foregroundColor(Theme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.primaryLight)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
        }
    }
}

// MARK: - TypeBadge
struct TypeBadge: View {
    let type: MeltdownType

    var body: some View {
        Text(type.displayName)
            .font(Theme.captionFont(12))
            .foregroundColor(Theme.color(for: type))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.lightColor(for: type))
            .clipShape(Capsule())
    }
}

// MARK: - SelectableChip
struct SelectableChip: View {
    let icon:       String
    let label:      String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                Text(label)
                    .font(Theme.captionFont(11))
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 76, height: 70)
            .background(isSelected ? Theme.primary : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerS)
                    .stroke(isSelected ? Theme.primary : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SectionLabel
struct SectionLabel: View {
    let title: String
    var color: Color = Theme.primary

    var body: some View {
        Text(title)
            .font(Theme.headlineFont(15))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - EmptyState
struct EmptyState: View {
    let icon:     String
    let title:    String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(Theme.textBlue)
            Text(title)
                .font(Theme.headlineFont())
                .foregroundColor(Theme.textBlue)
            Text(subtitle)
                .font(Theme.bodyFont())
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - EventRow
struct EventRow: View {
    let event: MeltdownEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.color(for: event.type))
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.type.displayName)
                    .font(Theme.headlineFont(15))
                    .foregroundColor(Theme.textPrimary)
                Text(event.date, style: .time)
                    .font(Theme.captionFont())
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
            TypeBadge(type: event.type)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows   = makeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
                         .reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in makeRows(proposal: proposal, subviews: subviews) {
            var x       = bounds.minX
            let rowH    = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for sub in row {
                let size = sub.sizeThatFits(.unspecified)
                sub.place(at: CGPoint(x: x, y: y), proposal: .init(size))
                x += size.width + spacing
            }
            y += rowH + spacing
        }
    }

    private func makeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxW = proposal.width ?? .infinity
        for sub in subviews {
            let w = sub.sizeThatFits(.unspecified).width
            if x + w > maxW, !rows[rows.endIndex - 1].isEmpty {
                rows.append([]); x = 0
            }
            rows[rows.endIndex - 1].append(sub)
            x += w + spacing
        }
        return rows
    }
}
