import Foundation

// Encodes a Workout into a Zwift .zwo XML workout file
enum WorkoutToZWO {

    static func encode(_ workout: Workout) -> Data {
        var lines: [String] = []
        lines.append("<workout_file>")
        lines.append("  <author>\(esc(workout.author))</author>")
        lines.append("  <name>\(esc(workout.name))</name>")
        lines.append("  <description>\(esc(workout.description))</description>")
        lines.append("  <sportType>\(sportType(workout.sport))</sportType>")
        lines.append("  <tags/>")
        lines.append("  <workout>")

        var i = 0
        let steps = workout.steps
        while i < steps.count {
            let step = steps[i]

            // Try to fold consecutive work+rest pairs into IntervalsT
            if step.intensity == .work,
               i + 1 < steps.count,
               steps[i + 1].intensity == .rest {
                let onDur  = step.durationSeconds
                let offDur = steps[i + 1].durationSeconds
                let onPwr  = fmt(power(step))
                let offPwr = fmt(power(steps[i + 1]))
                var count  = 1
                var j = i + 2
                while j + 1 < steps.count,
                      steps[j].intensity == .work,
                      steps[j + 1].intensity == .rest,
                      steps[j].durationSeconds == onDur,
                      steps[j + 1].durationSeconds == offDur {
                    count += 1
                    j += 2
                }
                // Also count a lone trailing work step without rest
                var trailingWork = false
                if j < steps.count,
                   steps[j].intensity == .work,
                   steps[j].durationSeconds == onDur {
                    trailingWork = true
                    count += 1
                    j += 1
                }
                if count >= 2 {
                    lines.append("    <IntervalsT Repeat=\"\(trailingWork ? count - 1 : count)\" OnDuration=\"\(onDur)\" OffDuration=\"\(offDur)\" OnPower=\"\(onPwr)\" OffPower=\"\(offPwr)\"/>")
                    if trailingWork {
                        lines.append("    <SteadyState Duration=\"\(onDur)\" Power=\"\(onPwr)\"/>")
                    }
                    i = j
                    continue
                }
            }

            switch step.intensity {
            case .warmup:
                let hi = fmt(power(step))
                lines.append("    <Warmup Duration=\"\(step.durationSeconds)\" PowerLow=\"0.25\" PowerHigh=\"\(hi)\"/>")
            case .cooldown:
                let lo = fmt(power(step))
                lines.append("    <Cooldown Duration=\"\(step.durationSeconds)\" PowerLow=\"\(lo)\" PowerHigh=\"0.25\"/>")
            case .work, .rest:
                if step.targetType == .open {
                    lines.append("    <FreeRide Duration=\"\(step.durationSeconds)\"/>")
                } else {
                    lines.append("    <SteadyState Duration=\"\(step.durationSeconds)\" Power=\"\(fmt(power(step)))\"/>")
                }
            }
            i += 1
        }

        lines.append("  </workout>")
        lines.append("</workout_file>")
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - Helpers

    private static func power(_ step: WorkoutStep) -> Double {
        step.zone?.ifValue ?? step.ftpPercent.map { $0 / 100.0 } ?? step.intensity.baseIF
    }

    private static func fmt(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    private static func sportType(_ sport: Sport) -> String {
        switch sport {
        case .cycling:  "bike"
        case .running:  "run"
        case .swimming: "swim"
        }
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
