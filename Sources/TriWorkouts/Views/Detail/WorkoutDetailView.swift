import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sportHeader
                mainStats
                IntervalChartView(steps: workout.steps, totalDuration: workout.totalDurationSeconds)
                timeBreakdown
                zoneDistribution
                IntervalTableView(steps: workout.steps)
                descriptionSection
                authorSection
                if let source = workout.source {
                    SourceSection(source: source)
                }
                Spacer(minLength: 32)
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle(workout.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FITDownloadButton(workout: workout)
            }
        }
    }

    // MARK: - Sport header + tags

    private var sportHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: workout.sport.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(workout.sport.color)
                Text(workout.sport.displayName)
                    .font(.headline)
                    .foregroundStyle(workout.sport.color)
                Spacer()
                difficultyLabel
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(workout.sport.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workout.tags, id: \.self) { TagChip(tag: $0) }
                }
            }
        }
    }

    private var difficultyLabel: some View {
        let (color, label): (Color, String) = switch workout.tss {
        case ..<60:    (.blue,   "Easy")
        case 60..<85:  (.green,  "Moderat")
        case 85..<105: (.orange, "Hart")
        default:       (.red,    "Sehr Hart")
        }
        return HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(color)
        }
    }

    // MARK: - Main stats

    private var mainStats: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()),
                      GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            StatCard(icon: "clock.fill",      label: "Gesamt",     value: workout.formattedDuration,                          color: .secondary)
            StatCard(icon: "bolt.fill",       label: "TSS",         value: "\(workout.tss)",                                   color: .orange)
            StatCard(icon: "waveform.path",   label: "IF",          value: String(format: "%.2f", workout.intensityFactor),    color: workout.sport.color)
            StatCard(icon: "repeat",          label: "Intervalle",  value: "\(workout.intervalCount)",                         color: .blue)
        }
    }

    // MARK: - Time breakdown

    private var timeBreakdown: some View {
        let workSec  = workout.steps.filter { $0.intensity == .work     }.reduce(0) { $0 + $1.durationSeconds }
        let restSec  = workout.steps.filter { $0.intensity == .rest     }.reduce(0) { $0 + $1.durationSeconds }
        let warmSec  = workout.steps.filter { $0.intensity == .warmup   }.reduce(0) { $0 + $1.durationSeconds }
        let coolSec  = workout.steps.filter { $0.intensity == .cooldown }.reduce(0) { $0 + $1.durationSeconds }
        let total    = Double(max(1, workout.totalDurationSeconds))

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Trainingszeit-Aufschlüsselung", icon: "chart.bar.fill")

            VStack(spacing: 8) {
                TimeBar(label: "Arbeit",      seconds: workSec, total: total, color: .orange)
                TimeBar(label: "Erholung",    seconds: restSec, total: total, color: Color(white: 0.45))
                TimeBar(label: "Warm-up",     seconds: warmSec, total: total, color: .blue)
                TimeBar(label: "Cool-down",   seconds: coolSec, total: total, color: .cyan)
            }
            .padding(14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
        }
    }

    // MARK: - Zone distribution

    private var zoneDistribution: some View {
        let zonedSteps = workout.steps.compactMap { step -> (PowerZone, Int)? in
            guard let z = step.zone else { return nil }
            return (z, step.durationSeconds)
        }
        guard !zonedSteps.isEmpty else { return AnyView(EmptyView()) }

        let grouped = Dictionary(grouping: zonedSteps, by: { $0.0 })
            .mapValues { $0.reduce(0) { $0 + $1.1 } }
        let total = Double(max(1, grouped.values.reduce(0, +)))
        let sortedZones = PowerZone.allCases.filter { grouped[$0] != nil }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Zonenverteilung", icon: "square.3.layers.3d")

                VStack(spacing: 8) {
                    ForEach(sortedZones, id: \.self) { zone in
                        let secs = grouped[zone] ?? 0
                        TimeBar(
                            label: "\(zone.rawValue) · \(zone.name)",
                            seconds: secs,
                            total: total,
                            color: zone.color,
                            showPercent: true
                        )
                    }
                }
                .padding(14)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
            }
        )
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Beschreibung", icon: "text.alignleft")
            Text(workout.description)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Author

    private var authorSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(workout.sport.color.opacity(0.8))
            VStack(alignment: .leading, spacing: 2) {
                Text("Autor").font(.caption).foregroundStyle(.tertiary)
                Text(workout.author).font(.callout.weight(.medium)).foregroundStyle(.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
    }

    // MARK: - Helper

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Time bar

private struct TimeBar: View {
    let label: String
    let seconds: Int
    let total: Double
    let color: Color
    var showPercent: Bool = false

    private var fraction: Double { min(1, Double(seconds) / total) }
    private var minutes: Int { seconds / 60 }
    private var formatted: String {
        let m = seconds / 60; let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12)).frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.8))
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 14)

            HStack(spacing: 4) {
                Text(formatted)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                if showPercent {
                    Text("(\(Int(fraction * 100))%)")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .frame(width: 90, alignment: .trailing)
        }
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let icon: String; let label: String; let value: String; let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.callout).foregroundStyle(color)
            Text(value).font(.system(.title3, design: .monospaced).weight(.bold)).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
    }
}

// MARK: - Source section

struct SourceSection: View {
    let source: WorkoutSource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Wissenschaftliche Quelle", systemImage: "graduationcap.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    sourceTypeBadge
                    Spacer()
                    Text("\(source.year)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                Text(source.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(source.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let inst = source.institution {
                    Label(inst, systemImage: "building.columns")
                        .font(.caption).foregroundStyle(.tertiary)
                }

                if let doi = source.doi {
                    HStack(spacing: 5) {
                        Image(systemName: "link").font(.caption2)
                        Text("DOI: \(doi)")
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.blue.opacity(0.85))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.25), lineWidth: 1))
        }
    }

    private var sourceTypeBadge: some View {
        let (icon, label): (String, String) = switch source.type {
        case "paper": ("doc.text", "Paper")
        case "book":  ("book.closed", "Buch")
        case "thesis":("graduationcap", "Dissertation")
        default:      ("person.fill", "Coaching")
        }
        return Label(label, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.blue)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.blue.opacity(0.10), in: Capsule())
    }
}

// MARK: - FIT Download

struct FITDownloadButton: View {
    let workout: Workout
    @State private var isGenerating = false
    @State private var fitFileURL: URL?
    @State private var showShare = false

    var body: some View {
        Button { generateAndShare() } label: {
            if isGenerating {
                ProgressView().controlSize(.small)
            } else {
                Label("Download .FIT", systemImage: "square.and.arrow.down")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(workout.sport.color)
        #if os(iOS)
        .sheet(isPresented: $showShare) {
            if let url = fitFileURL { ShareSheet(url: url) }
        }
        #endif
    }

    private func generateAndShare() {
        isGenerating = true
        Task.detached(priority: .userInitiated) {
            let data = WorkoutToFIT.encode(workout)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(workout.id).fit")
            try? data.write(to: url)
            await MainActor.run {
                isGenerating = false
                #if os(macOS)
                savePanelMacOS(url: url)
                #else
                fitFileURL = url; showShare = true
                #endif
            }
        }
    }

    #if os(macOS)
    private func savePanelMacOS(url: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(workout.id).fit"
        panel.allowedContentTypes = [.data]
        panel.message = "Save \(workout.name) as .fit file for Garmin / Wahoo / Zwift"
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: url, to: dest)
        }
    }
    #endif
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
#endif
