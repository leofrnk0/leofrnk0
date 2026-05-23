import SwiftUI

// MARK: - Step grouping

private enum StepGroup: Identifiable {
    case single(WorkoutStep)
    case repeated(count: Int, pattern: [WorkoutStep], totalSeconds: Int, lastIsPartial: Bool)

    var id: String {
        switch self {
        case .single(let s):                  return "s_\(s.id)"
        case .repeated(let c, let p, _, _):  return "r_\(c)_\(p.first?.id ?? 0)"
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
        var bestHasPartial = false

        for len in 1...min(4, remaining) {
            let pattern = Array(steps[i..<(i + len)])
            var count = 1
            var j = i + len
            while j + len <= steps.count && stepsMatch(Array(steps[j..<(j + len)]), pattern) {
                count += 1
                j += len
            }
            guard count >= 2 else { continue }

            let hasPartial = len > 1 && j < steps.count && stepsMatch([steps[j]], [pattern[0]])
            let score = count * len + (hasPartial ? 1 : 0)
            let bestScore = bestCount * bestLen + (bestHasPartial ? 1 : 0)
            if score > bestScore {
                bestLen = len; bestCount = count; bestHasPartial = hasPartial
            }
        }

        if bestCount >= 2 {
            let pattern = Array(steps[i..<(i + bestLen)])
            let displayCount = bestHasPartial ? bestCount + 1 : bestCount
            let fullSecs   = pattern.reduce(0) { $0 + $1.durationSeconds } * bestCount
            let partialSecs = bestHasPartial ? pattern[0].durationSeconds : 0
            groups.append(.repeated(count: displayCount, pattern: pattern,
                                    totalSeconds: fullSecs + partialSecs,
                                    lastIsPartial: bestHasPartial))
            i += bestLen * bestCount + (bestHasPartial ? 1 : 0)
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

private func formatMeters(_ m: Int) -> String {
    m >= 1000 ? String(format: "%.1f km", Double(m) / 1000.0) : "\(m) m"
}

// MARK: - Main view

struct IntervalTableView: View {
    let steps: [WorkoutStep]
    var sport: Sport = .cycling

    private var isSwim: Bool { sport == .swimming }
    private var groups: [StepGroup] { groupSteps(steps) }

    private var totalSwimMeters: Int {
        steps.compactMap(\.distanceMeters).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Label("Steps (\(steps.count))", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                if isSwim && totalSwimMeters > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.pool.swim")
                            .font(.callout)
                        Text(formatMeters(totalSwimMeters))
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                    }
                    .foregroundStyle(Color.mutedCyan)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.mutedCyan.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(Color.mutedCyan.opacity(0.35), lineWidth: 1))
                }
            }

            VStack(spacing: 0) {
                tableHeader
                Divider().background(Color.appBorder)
                ForEach(Array(groups.enumerated()), id: \.element.id) { idx, group in
                    switch group {
                    case .single(let step):
                        StepRow(step: step, displayIndex: idx + 1, isSwim: isSwim)
                    case .repeated(let count, let pattern, let total, _):
                        RepeatGroupRow(count: count, pattern: pattern,
                                       totalSeconds: total, displayIndex: idx + 1, isSwim: isSwim)
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
            Text("Type").frame(width: 90, alignment: .leading)
            Text(isSwim ? "Equipment" : "Zone")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(isSwim ? "Dist." : "Duration").frame(width: 72, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 12).padding(.vertical, 7)
    }
}

// MARK: - Single step row

private struct StepRow: View {
    let step: WorkoutStep
    let displayIndex: Int
    let isSwim: Bool
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    Text("\(displayIndex)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
                        .frame(width: 36, alignment: .center)

                    IntensityBadge(intensity: step.intensity)
                        .frame(width: 90, alignment: .leading)

                    // Middle column: equipment (swim) or zone
                    if isSwim {
                        equipmentRow(step.equipment ?? [])
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(spacing: 6) {
                            Circle().fill(step.zoneColor).frame(width: 8, height: 8)
                            Text(zoneLabel)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }

                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 60, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, alignment: .center)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(step.zoneColor.opacity(isExpanded ? 0.06 : 0.0))

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle().fill(step.zoneColor.opacity(0.6))
                            .frame(width: 2).cornerRadius(1)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.description)
                                .font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            // For swimming: show HR zone in description area
                            if isSwim, let n = step.targetZoneNumber {
                                Text("HR Zone \(n)")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            } else if isSwim, let z = step.zone {
                                Text("\(z.rawValue) · \(z.name)")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            } else if let rpm = step.cadence {
                                Label("\(rpm) rpm", systemImage: "arrow.clockwise")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.mutedBlue)
                            }
                        }
                        Spacer()
                    }
                    // Equipment chips in expanded area for non-swim (swim shows in row)
                    if !isSwim, let eq = step.equipment, !eq.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(eq, id: \.self) { item in
                                    Label(item.rawValue, systemImage: item.icon)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color.mutedCyan)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color.mutedCyan.opacity(0.12), in: Capsule())
                                        .overlay(Capsule().stroke(Color.mutedCyan.opacity(0.35), lineWidth: 0.5))
                                }
                            }
                        }
                        .padding(.leading, 12)
                    }
                }
                .padding(.leading, 44).padding(.trailing, 16)
                .padding(.top, 4).padding(.bottom, 10)
                .background(step.zoneColor.opacity(0.04))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }

    @ViewBuilder
    private func equipmentRow(_ eq: [SwimEquipment]) -> some View {
        if eq.isEmpty {
            Text("—").font(.caption).foregroundStyle(Color(white: 0.3))
        } else {
            HStack(spacing: 4) {
                ForEach(eq, id: \.self) { item in
                    HStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.caption2)
                        Text(item.rawValue)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.mutedCyan)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.mutedCyan.opacity(0.10), in: Capsule())
                }
            }
        }
    }

    private var zoneLabel: String {
        if let z = step.zone { return "\(z.rawValue) · \(z.name)" }
        if let pct = step.ftpPercent { return "\(Int(pct))% FTP" }
        if let n = step.targetZoneNumber { return "HR Zone \(n)" }
        return "Open"
    }
}

// MARK: - Repeat group row

private struct RepeatGroupRow: View {
    let count: Int
    let pattern: [WorkoutStep]
    let totalSeconds: Int
    let displayIndex: Int
    let isSwim: Bool
    @State private var isExpanded = false

    private var totalSwimMeters: Int {
        pattern.compactMap(\.distanceMeters).reduce(0, +) * count
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(Color.appElevated)
                        Text("\(count)×").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                    }
                    .frame(width: 36, height: 22)

                    // Pattern summary
                    HStack(spacing: 5) {
                        ForEach(Array(pattern.enumerated()), id: \.offset) { idx, step in
                            HStack(spacing: 3) {
                                Circle().fill(step.zoneColor).frame(width: 7, height: 7)
                                Text(step.formattedDuration)
                                    .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            if idx < pattern.count - 1 {
                                Text("+").font(.caption2).foregroundStyle(Color.appBorder)
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)

                    // Total: show metres for swim, time for others
                    Text(isSwim && totalSwimMeters > 0 ? formatMeters(totalSwimMeters) : formattedTime)
                        .font(.system(.callout, design: .monospaced).weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 60, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, alignment: .center)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(pattern.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: 0) {
                            Spacer().frame(width: 36)
                            IntensityBadge(intensity: step.intensity)
                                .frame(width: 90, alignment: .leading)

                            if isSwim {
                                // Equipment inline
                                let eq = step.equipment ?? []
                                if eq.isEmpty {
                                    Text("—").font(.caption).foregroundStyle(Color(white: 0.3))
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 4) {
                                            ForEach(eq, id: \.self) { item in
                                                HStack(spacing: 3) {
                                                    Image(systemName: item.icon).font(.caption2)
                                                    Text(item.rawValue).font(.caption2.weight(.semibold))
                                                }
                                                .foregroundStyle(Color.mutedCyan)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color.mutedCyan.opacity(0.10), in: Capsule())
                                            }
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Circle().fill(step.zoneColor).frame(width: 8, height: 8)
                                    Text(zoneLabel(step)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }

                            Text(step.formattedDuration)
                                .font(.system(.callout, design: .monospaced).weight(.medium))
                                .foregroundStyle(.primary)
                                .frame(width: 60, alignment: .trailing)
                            Spacer().frame(width: 20)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
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

    private var formattedTime: String {
        let m = totalSeconds / 60; let s = totalSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m)m \(s)s"
    }

    private func zoneLabel(_ step: WorkoutStep) -> String {
        if let z = step.zone { return "\(z.rawValue) · \(z.name)" }
        if let pct = step.ftpPercent { return "\(Int(pct))% FTP" }
        if let n = step.targetZoneNumber { return "HR Zone \(n)" }
        return "Open"
    }
}

// MARK: - Intensity badge

private struct IntensityBadge: View {
    let intensity: StepIntensity

    private var color: Color {
        switch intensity {
        case .warmup:   Color.mutedBlue
        case .work:     Color.mutedOrange
        case .rest:     Color(white: 0.40)
        case .cooldown: Color.mutedCyan
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
