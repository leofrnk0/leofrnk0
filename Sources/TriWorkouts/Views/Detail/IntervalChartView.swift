import SwiftUI

struct IntervalChartView: View {
    let steps: [WorkoutStep]
    let totalDuration: Int

    @State private var hoveredStep: WorkoutStep?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Interval Structure")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(steps) { step in
                        let w = max(4, geo.size.width * CGFloat(step.durationSeconds) / CGFloat(max(1, totalDuration)))
                        ZoneBlock(step: step, width: w, isHovered: hoveredStep?.id == step.id)
                            .onHover { hovered in
                                hoveredStep = hovered ? step : nil
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 72)

            // Tooltip
            if let step = hoveredStep {
                HStack(spacing: 8) {
                    Circle()
                        .fill(step.zoneColor)
                        .frame(width: 8, height: 8)
                    Text(step.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(step.formattedDuration)
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.primary)
                    if let zone = step.zone {
                        Text(zone.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(zone.color)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Zone legend
            zoneLegend
        }
        .animation(.easeOut(duration: 0.15), value: hoveredStep?.id)
    }

    private var usedZones: [PowerZone] {
        let zones = steps.compactMap(\.zone)
        return PowerZone.allCases.filter { zones.contains($0) }
    }

    private var zoneLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(usedZones, id: \.self) { zone in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(zone.color)
                            .frame(width: 12, height: 12)
                        Text(zone.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(zone.ftpRange)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

private struct ZoneBlock: View {
    let step: WorkoutStep
    let width: CGFloat
    let isHovered: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(step.zoneColor.opacity(isHovered ? 1.0 : 0.85))
            .frame(width: width)
            .overlay(
                isHovered
                ? RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
                : nil
            )
            .scaleEffect(y: isHovered ? 1.05 : 1.0, anchor: .bottom)
            .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}
