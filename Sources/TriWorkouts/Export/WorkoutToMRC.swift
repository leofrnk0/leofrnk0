import Foundation

// Encodes a Workout into a TrainerRoad / Sufferfest .mrc file.
// Reference FTP = 250 W  (adjust in your training software after loading).
enum WorkoutToMRC {

    static let referenceFTP = 250

    static func encode(_ workout: Workout) -> Data {
        let slug = workout.name
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: "-")

        var out = """
            [COURSE HEADER]
            DESCRIPTION = \(workout.name)
            FILE NAME = \(slug)
            MINUTES WATTS
            [END COURSE HEADER]
            [COURSE DATA]

            """

        var time = 0.0   // minutes
        var lines: [String] = []

        for (idx, step) in workout.steps.enumerated() {
            let dur    = Double(step.durationSeconds) / 60.0
            let target = power(step)
            let endT   = time + dur

            switch step.intensity {
            case .warmup:
                let startW = idx == 0 ? Double(referenceFTP) * 0.25 : prevWatts(workout.steps, idx)
                lines.append(pt(time, startW))
                lines.append(pt(endT, target))
            case .cooldown:
                lines.append(pt(time, target))
                lines.append(pt(endT, Double(referenceFTP) * 0.25))
            default:
                // Step function: tiny gap creates a near-instant transition
                let prev = idx > 0 ? prevWatts(workout.steps, idx) : target
                if abs(prev - target) > 1 {
                    lines.append(pt(time + 0.001, target))
                } else {
                    lines.append(pt(time, target))
                }
                lines.append(pt(endT, target))
            }
            time = endT
        }

        // De-duplicate consecutive identical lines and ensure monotone time
        var prev: String? = nil
        for line in lines {
            if line != prev { out += line + "\n" }
            prev = line
        }

        out += "[END COURSE DATA]\n"
        return out.data(using: .utf8) ?? Data()
    }

    // MARK: - Helpers

    private static func power(_ step: WorkoutStep) -> Double {
        let fraction = step.zone?.ifValue ?? step.intensity.baseIF
        return (fraction * Double(referenceFTP)).rounded()
    }

    private static func prevWatts(_ steps: [WorkoutStep], _ idx: Int) -> Double {
        guard idx > 0 else { return Double(referenceFTP) * 0.25 }
        return power(steps[idx - 1])
    }

    private static func pt(_ minutes: Double, _ watts: Double) -> String {
        String(format: "%.3f\t%.0f", minutes, watts)
    }
}
