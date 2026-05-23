import Foundation
import SwiftUI

// MARK: - Sport

enum Sport: String, Codable, CaseIterable, Hashable {
    case swimming, cycling, running

    var displayName: String {
        switch self {
        case .cycling:  "Cycling"
        case .running:  "Running"
        case .swimming: "Swimming"
        }
    }

    var color: Color {
        switch self {
        case .cycling:  Color.mutedOrange
        case .running:  Color.mutedGreen
        case .swimming: Color.mutedCyan
        }
    }

    var icon: String {
        switch self {
        case .cycling:  "bicycle"
        case .running:  "figure.run"
        case .swimming: "figure.pool.swim"
        }
    }

    var fitValue: UInt8 {
        switch self {
        case .cycling:  2
        case .running:  1
        case .swimming: 5
        }
    }
}

// MARK: - WorkoutTag

enum WorkoutTag: String, Codable, CaseIterable, Hashable {
    case vo2max       = "VO2max"
    case sweetSpot    = "Sweet Spot"
    case endurance    = "Endurance"
    case tempo        = "Tempo"
    case threshold    = "Threshold"
    case recovery     = "Recovery"
    case sprint       = "Sprint"
    case technique    = "Technique"
    case assessment   = "Assessment"
    case trackSession = "Track Session"
    case racePrep     = "Race Prep"
    case css          = "CSS"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .vo2max:       Color.mutedOrange
        case .sweetSpot:    Color.mutedYellow
        case .endurance:    Color.mutedBlue
        case .tempo:        Color.mutedGreen
        case .threshold:    Color.mutedYellow
        case .recovery:     Color(white: 0.42)
        case .sprint:       Color.mutedRed
        case .technique:    Color.mutedPurple
        case .assessment:   Color.mutedCyan
        case .trackSession: Color.mutedGreen
        case .racePrep:     Color.mutedRed
        case .css:          Color.mutedCyan
        }
    }
}

// MARK: - PowerZone

enum PowerZone: String, Codable, CaseIterable, Hashable {
    case z1 = "Z1", z2 = "Z2", z3 = "Z3", z4 = "Z4", z5 = "Z5"

    var name: String {
        switch self {
        case .z1: "Recovery"
        case .z2: "Endurance"
        case .z3: "Tempo"
        case .z4: "Threshold"
        case .z5: "VO2max"
        }
    }

    var color: Color {
        switch self {
        case .z1: Color(white: 0.40)
        case .z2: Color.mutedBlue
        case .z3: Color.mutedGreen
        case .z4: Color.mutedOrange
        case .z5: Color.mutedRed
        }
    }

    var fitIndex: UInt32 {
        switch self {
        case .z1: 1; case .z2: 2; case .z3: 3; case .z4: 4; case .z5: 5
        }
    }

    var ftpRange: String {
        switch self {
        case .z1: "< 55%"
        case .z2: "55–75%"
        case .z3: "76–90%"
        case .z4: "91–105%"
        case .z5: "> 105%"
        }
    }

    // Approximate Intensity Factor for IF/TSS calculation
    var ifValue: Double {
        switch self {
        case .z1: 0.52
        case .z2: 0.65
        case .z3: 0.82
        case .z4: 0.97
        case .z5: 1.12
        }
    }

    // Relative bar height in the profile chart (0–1, bottom-anchored)
    var heightFactor: CGFloat {
        switch self {
        case .z1: 0.12
        case .z2: 0.35
        case .z3: 0.58
        case .z4: 0.78
        case .z5: 1.00
        }
    }
}

// MARK: - StepIntensity

enum StepIntensity: String, Codable {
    case warmup, work, rest, cooldown

    var fitValue: UInt8 {
        switch self {
        case .warmup:   2
        case .work:     0
        case .rest:     1
        case .cooldown: 3
        }
    }

    // Approximate IF when no zone is set
    var baseIF: Double {
        switch self {
        case .warmup:   0.58
        case .work:     0.90
        case .rest:     0.45
        case .cooldown: 0.55
        }
    }

    var displayName: String {
        switch self {
        case .warmup:   "Warm-up"
        case .work:     "Work"
        case .rest:     "Rest"
        case .cooldown: "Cool-down"
        }
    }
}

// MARK: - TargetType

enum TargetType: String, Codable {
    case powerZone    = "power_zone"
    case heartRateZone = "heart_rate_zone"
    case paceZone     = "pace_zone"
    case open

    var fitValue: UInt8 {
        switch self {
        case .powerZone:     4
        case .heartRateZone: 1
        case .paceZone:      1
        case .open:          2
        }
    }
}

// MARK: - WorkoutStep

struct WorkoutStep: Codable, Identifiable {
    let id: Int
    let intensity: StepIntensity
    let durationSeconds: Int
    let targetType: TargetType
    let zone: PowerZone?
    let targetZoneNumber: Int?
    let powerLowPercent: Double?
    let powerHighPercent: Double?
    let description: String
    let repeatCount: Int?

    var zoneColor: Color {
        if let z = zone { return z.color }
        switch intensity {
        case .warmup:   return Color(white: 0.35)
        case .rest:     return Color(white: 0.20)
        case .cooldown: return Color(white: 0.30)
        case .work:     return Color.mutedOrange
        }
    }

    // Relative bar height for the profile chart (0–1, bottom-anchored)
    var heightFactor: CGFloat {
        if let z = zone { return z.heightFactor }
        switch intensity {
        case .warmup:   return 0.22
        case .work:     return 0.72
        case .rest:     return 0.08
        case .cooldown: return 0.18
        }
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m)m \(s)s"
    }
}

// MARK: - WorkoutSource

struct WorkoutSource: Codable {
    let type: String
    let title: String
    let authors: [String]
    let year: Int
    let doi: String?
    let url: String?
    let institution: String?
}

// MARK: - Workout

struct Workout: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let sport: Sport
    let tags: [WorkoutTag]
    let totalDurationSeconds: Int
    let tss: Int
    let intensityFactor: Double
    let description: String
    let author: String
    let steps: [WorkoutStep]
    let source: WorkoutSource?

    var intervalCount: Int {
        steps.filter { $0.intensity == .work }.count
    }

    var formattedDuration: String {
        let minutes = totalDurationSeconds / 60
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 { return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h" }
        return "\(mins)min"
    }

    var workSeconds: Int {
        steps.filter { $0.intensity == .work }.reduce(0) { $0 + $1.durationSeconds }
    }

    static func == (lhs: Workout, rhs: Workout) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
