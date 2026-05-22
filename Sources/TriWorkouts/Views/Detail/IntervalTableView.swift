import SwiftUI

struct IntervalTableView: View {
    let steps: [WorkoutStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                // Header
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 32, alignment: .center)
                    Text("Type")
                        .frame(width: 90, alignment: .leading)
                    Text("Zone")
                        .frame(width: 100, alignment: .leading)
                    Text("Duration")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Divider().background(Color.appBorder)

                ForEach(steps) { step in
                    StepRow(step: step)
                }
            }
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
    }
}

private struct StepRow: View {
    let step: WorkoutStep
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    Text("\(step.id + 1)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, alignment: .center)

                    IntensityBadge(intensity: step.intensity)
                        .frame(width: 90, alignment: .leading)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(step.zoneColor)
                            .frame(width: 8, height: 8)
                        Text(zoneLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, alignment: .leading)

                    Spacer()

                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(step.zoneColor.opacity(0.04))

            if isExpanded {
                HStack {
                    Text(step.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 44)
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                    Spacer()
                }
                .background(step.zoneColor.opacity(0.06))
            }

            Divider().background(Color.appBorder).padding(.leading, 44)
        }
    }

    private var zoneLabel: String {
        if let z = step.zone { return "\(z.rawValue) · \(z.name)" }
        if let n = step.targetZoneNumber { return "HR Z\(n)" }
        return "Open"
    }
}

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
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}
