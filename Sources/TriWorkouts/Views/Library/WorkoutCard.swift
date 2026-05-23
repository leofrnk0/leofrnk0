import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    var isSelected: Bool = false
    @State private var isHovered = false

    private var highlighted: Bool { isSelected || isHovered }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sport colour accent bar
            Rectangle()
                .fill(workout.sport.color)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 12) {
                headerRow
                tagRow
                Divider().background(Color.appBorder)
                statsRow
            }
            .padding(16)
        }
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    highlighted ? workout.sport.color.opacity(0.6) : Color.appBorder,
                    lineWidth: highlighted ? 1.5 : 1
                )
        )
        .shadow(color: highlighted ? workout.sport.color.opacity(0.15) : .black.opacity(0.15), radius: highlighted ? 14 : 4, y: 2)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .onHover { isHovered = $0 }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Image(systemName: workout.sport.icon).font(.caption2)
                    Text(workout.sport.displayName).font(.caption)
                }
                .foregroundStyle(workout.sport.color)
            }
            Spacer()
            difficultyBadge
        }
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(workout.tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(icon: "clock",            value: workout.formattedDuration,                         label: "Dauer")
            dividerLine
            StatItem(icon: "bolt",             value: "\(workout.tss)",                                  label: "TSS")
            dividerLine
            StatItem(icon: "repeat",           value: "\(workout.intervalCount)",                        label: "Intervalle")
            dividerLine
            StatItem(icon: "waveform.path.ecg",value: String(format: "%.2f", workout.intensityFactor),  label: "IF")
        }
    }

    private var dividerLine: some View {
        Divider().frame(height: 28).background(Color.appBorder)
    }

    private var difficultyBadge: some View {
        let (color, label): (Color, String) = switch workout.tss {
        case ..<60:    (Color.mutedBlue,   "Easy")
        case 60..<85:  (Color.mutedGreen,  "Moderat")
        case 85..<105: (Color.mutedOrange, "Hart")
        default:       (Color.mutedRed,    "Sehr Hart")
        }
        return Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Shared components

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TagChip: View {
    let tag: WorkoutTag

    var body: some View {
        Text(tag.displayName)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tag.color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(tag.color.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tag.color.opacity(0.3), lineWidth: 0.5))
    }
}

// Simple horizontal tag row (used in detail view)
struct FlowRow<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        var width: CGFloat = 0
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width { width = 0 }
                            let result = width
                            if item == items.last { width = 0 } else { width -= d.width + 6 }
                            return result
                        }
                }
            }
        }
        .frame(height: 22)
    }
}
