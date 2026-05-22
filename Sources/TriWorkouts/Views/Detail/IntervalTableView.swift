import SwiftUI

// MARK: - Step grouping

private enum StepGroup: Identifiable {
    case single(WorkoutStep)
    case repeated(count: Int, pattern: [WorkoutStep], totalSeconds: Int)

    var id: String {
        switch self {
        case .single(let s):              return "s_\(s.id)"
        case .repeated(let c, let p, _): return "r_\(c)_\(p.first?.id ?? 0)"
        }
    }
}

private func groupSteps(_ steps: [WorkoutStep]) -> [StepGroup] {
    var groups: [StepGroup] = []
    var i = 0
    while i < steps.count {
        let remaining = steps.count - i
        var bestLen = 1
        var bestCount = 1

        for len in 1...min(4, remaining) {
            let pattern = Array(steps[i..<(i + len)])
            var count = 1
            var j = i + len
            while j + len <= steps.count && stepsMatch(Array(steps[j..<(j + len)]), pattern) {
                count += 1
                j += len
            }
            if count > 1 && count * len > bestCount * bestLen {
                bestLen = len
                bestCount = count
            }
        }

        if bestCount >= 2 {
            let pattern = Array(steps[i..<(i + bestLen)])
            let total = pattern.reduce(0) { $0 + $1.durationSeconds } * bestCount
            groups.append(.repeated(count: bestCount, pattern: pattern, totalSeconds: total))
            i += bestLen * bestCount
        } else {
            groups.append(.single(steps[i]))
            i += 1
        }
    }
    return groups
}

private func stepsMatch(_ a: [WorkoutStep], _ b: [WorkoutStep]) -> Bool {
    guard a.count == b.count else { return false }
    return zip(a, b).allSatisfy {
        $0.intensity == $1.intensity &&
        $0.durationSeconds == $1.durationSeconds &&
        $0.zone == $1.zone
    }
}

// MARK: - Main view

struct IntervalTableView: View {
    let steps: [WorkoutStep]

    private var groups: [StepGroup] { groupSteps(steps) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Schritte (\(steps.count))", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                tableHeader
                Divider().background(Color.appBorder)
                ForEach(Array(groups.enumerated()), id: \.element.id) { idx, group in
                    switch group {
                    case .single(let step):
                        StepRow(step: step, displayIndex: idx + 1)
                    case .repeated(let count, let pattern, let total):
                        RepeatGroupRow(count: count, pattern: pattern, totalSeconds: total,
                                       displayIndex: idx + 1)
                    }
                    if idx < groups.count - 1 {
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

// MARK: - Single step row

private struct StepRow: View {
    let step: WorkoutStep
    let displayIndex: Int
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    Text("\(displayIndex)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 36, alignment: .center)

                    IntensityBadge(intensity: step.intensity)
                        .frame(width: 90, alignment: .leading)

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

                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 60, alignment: .trailing)

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

// MARK: - Repeat group row

private struct RepeatGroupRow: View {
    let count: Int
    let pattern: [WorkoutStep]
    let totalSeconds: Int
    let displayIndex: Int
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    // Repeat badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.appElevated)
                        Text("\(count)×")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 36, height: 22)

                    // Pattern dot-summary
                    HStack(spacing: 5) {
                        ForEach(Array(pattern.enumerated()), id: \.offset) { idx, step in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(step.zoneColor)
                                    .frame(width: 7, height: 7)
                                Text(step.formattedDuration)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            if idx < pattern.count - 1 {
                                Text("+").font(.caption2).foregroundStyle(Color.appBorder)
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)

                    Text(formattedTotal)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 60, alignment: .trailing)

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

            // Expanded: one row per unique step in the pattern
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(pattern.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: 0) {
                            Spacer().frame(width: 36)

                            IntensityBadge(intensity: step.intensity)
                                .frame(width: 90, alignment: .leading)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(step.zoneColor)
                                    .frame(width: 8, height: 8)
                                Text(zoneLabel(step))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                            Text(step.formattedDuration)
                                .font(.system(.callout, design: .monospaced).weight(.medium))
                                .foregroundStyle(.primary)
                                .frame(width: 60, alignment: .trailing)

                            Spacer().frame(width: 20)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(step.zoneColor.opacity(0.05))

                        if idx < pattern.count - 1 {
                            Divider().background(Color.appBorder).padding(.leading, 44)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExpanded)
        .background(Color.appElevated.opacity(isExpanded ? 0.25 : 0))
    }

    private var formattedTotal: String {
        let m = totalSeconds / 60; let s = totalSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m)m \(s)s"
    }

    private func zoneLabel(_ step: WorkoutStep) -> String {
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
