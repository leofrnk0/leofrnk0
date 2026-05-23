import SwiftUI

struct IntervalChartView: View {
    let steps: [WorkoutStep]
    let totalDuration: Int

    @State private var selectedStep: WorkoutStep?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader

            // Profile chart — bars bottom-aligned, height = intensity
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Baseline
                    Rectangle()
                        .fill(Color.appBorder)
                        .frame(height: 1)

                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(steps) { step in
                            let w = max(4, geo.size.width * CGFloat(step.durationSeconds) / CGFloat(max(1, totalDuration)))
                            let h = max(6, geo.size.height * step.heightFactor)
                            ZoneBlock(step: step, width: w, height: h,
                                      isHighlighted: selectedStep?.id == step.id)
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        selectedStep = selectedStep?.id == step.id ? nil : step
                                    }
                                }
                                #if os(macOS)
                                .onHover { hovered in
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        selectedStep = hovered ? step : nil
                                    }
                                }
                                #endif
                        }
                    }
                }
            }
            .frame(height: 88)

            // Tooltip / selected step info
            if let step = selectedStep {
                stepInfo(step)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                tapHint
            }

            // Zone legend
            if !usedZones.isEmpty {
                zoneLegend
            }
        }
        .animation(.easeOut(duration: 0.15), value: selectedStep?.id)
    }

    // MARK: - Subviews

    private var sectionHeader: some View {
        HStack {
            Label("Intervallstruktur", systemImage: "waveform.path.ecg")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(formattedTotal)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }

    private func stepInfo(_ step: WorkoutStep) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(step.zoneColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(step.intensity.displayName.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                Text(step.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(step.formattedDuration)
                    .font(.callout.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                if let zone = step.zone {
                    Text(zone.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(zone.color)
                } else if let n = step.targetZoneNumber {
                    Text("HR Z\(n)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder))
    }

    private var tapHint: some View {
        Text("Tap bar for details")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
    }

    private var zoneLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
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

    // MARK: - Helpers

    private var usedZones: [PowerZone] {
        let zones = steps.compactMap(\.zone)
        return PowerZone.allCases.filter { zones.contains($0) }
    }

    private var formattedTotal: String {
        let m = totalDuration / 60
        return m >= 60 ? "\(m / 60)h \(m % 60)min" : "\(m) min"
    }
}

// MARK: - Zone block

private struct ZoneBlock: View {
    let step: WorkoutStep
    let width: CGFloat
    let height: CGFloat
    let isHighlighted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(step.zoneColor.opacity(isHighlighted ? 1.0 : 0.82))
            .frame(width: width, height: height)
            .overlay(
                isHighlighted
                    ? RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.4), lineWidth: 1.5)
                    : nil
            )
            .scaleEffect(y: isHighlighted ? 1.08 : 1.0, anchor: .bottom)
            .animation(.easeOut(duration: 0.1), value: isHighlighted)
    }
}
