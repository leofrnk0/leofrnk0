import SwiftUI

struct IntervalTableView: View {
    let steps: [WorkoutStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Schritte (\(steps.count))", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                tableHeader
                Divider().background(Color.appBorder)
                ForEach(steps) { step in
                    StepRow(step: step)
                    if step.id != steps.last?.id {
                        Divider().background(Color.appBorder).padding(.leading, 44)
                    }
                }
            }
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 36, alignment: .center)
            Text("Typ").frame(width: 90, alignment: .leading)
            Text("Zone").frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text("Dauer").frame(width: 72, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}

// MARK: - Step row

private struct StepRow: View {
    let step: WorkoutStep
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    // Step number
                    Text("\(step.id + 1)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 36, alignment: .center)

                    // Intensity badge
                    IntensityBadge(intensity: step.intensity)
                        .frame(width: 90, alignment: .leading)

                    // Zone indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(step.zoneColor)
                            .frame(width: 8, height: 8)
                        Text(zoneLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    // Duration
                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 60, alignment: .trailing)

                    // Expand chevron
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, alignment: .center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(step.zoneColor.opacity(isExpanded ? 0.06 : 0.0))

            // Expanded description
            if isExpanded {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(step.zoneColor.opacity(0.6))
                        .frame(width: 2)
                        .cornerRadius(1)
                    Text(step.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.leading, 44)
                .padding(.trailing, 16)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .background(step.zoneColor.opacity(0.04))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }

    private var zoneLabel: String {
        if let z = step.zone { return "\(z.rawValue) · \(z.name)" }
        if let n = step.targetZoneNumber { return "HR Zone \(n)" }
        return "Offen"
    }
}

// MARK: - Intensity badge

private struct IntensityBadge: View {
    let intensity: StepIntensity

    private var color: Color {
        switch intensity {
        case .warmup:   .blue
        case .work:     .orange
        case .rest:     Color(white: 0.5)
        case .cooldown: .cyan
        }
    }

    var body: some View {
        Text(intensity.displayName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }
}
