import SwiftUI
#if os(macOS)
import AppKit
#endif

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sportHeader
                mainStats
                IntervalChartView(steps: workout.steps, totalDuration: workout.totalDurationSeconds)
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

    // MARK: - Sport header

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
        case ..<60:    (.mutedBlue,   "Easy")
        case 60..<85:  (.mutedGreen,  "Moderat")
        case 85..<105: (.mutedOrange, "Hart")
        default:       (.mutedRed,    "Sehr Hart")
        }
        return HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(color)
        }
    }

    // MARK: - Stats

    private var mainStats: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: 10
        ) {
            StatCard(icon: "clock.fill",    label: "Gesamt",    value: workout.formattedDuration,                        color: .secondary)
            StatCard(icon: "bolt.fill",     label: "TSS",       value: "\(workout.tss)",                                 color: .mutedOrange)
            StatCard(icon: "waveform.path", label: "IF",        value: String(format: "%.2f", workout.intensityFactor),  color: workout.sport.color)
            StatCard(icon: "repeat",        label: "Intervalle",value: "\(workout.intervalCount)",                        color: .mutedBlue)
        }
    }

    // MARK: - Time breakdown

    private var timeBreakdownData: [(label: String, seconds: Int, color: Color)] {
        [
            ("Arbeit",     workout.steps.filter { $0.intensity == .work     }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedOrange),
            ("Erholung",   workout.steps.filter { $0.intensity == .rest     }.reduce(0) { $0 + $1.durationSeconds }, Color(white: 0.40)),
            ("Warm-up",    workout.steps.filter { $0.intensity == .warmup   }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedBlue),
            ("Cool-down",  workout.steps.filter { $0.intensity == .cooldown }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedCyan),
        ].filter { $0.seconds > 0 }
    }

    private var timeBreakdown: some View {
        let data = timeBreakdownData
        let total = Double(max(1, workout.totalDurationSeconds))
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Trainingszeit-Aufschlüsselung", icon: "chart.bar.fill")
            VStack(spacing: 8) {
                ForEach(data, id: \.label) { item in
                    TimeBar(label: item.label, seconds: item.seconds, total: total, color: item.color)
                }
            }
            .padding(14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
        }
    }

    // MARK: - Zone distribution

    private var zoneStats: [(zone: PowerZone, seconds: Int)] {
        let grouped = Dictionary(
            grouping: workout.steps.compactMap { s -> (PowerZone, Int)? in
                guard let z = s.zone else { return nil }
                return (z, s.durationSeconds)
            },
            by: { $0.0 }
        ).mapValues { $0.reduce(0) { $0 + $1.1 } }
        // Always return all 5 zones (0 seconds if unused)
        return PowerZone.allCases.map { z in (z, grouped[z] ?? 0) }
    }

    @ViewBuilder
    private var zoneDistribution: some View {
        let stats = zoneStats
        let totalActive = Double(stats.reduce(0) { $0 + $1.seconds })
        if totalActive > 0 {
            let total = totalActive
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Zonenverteilung", icon: "square.3.layers.3d")
                VStack(spacing: 8) {
                    ForEach(stats, id: \.zone) { item in
                        TimeBar(
                            label: "\(item.zone.rawValue) · \(item.zone.name)",
                            seconds: item.seconds,
                            total: total,
                            color: item.zone.color,
                            showPercent: true
                        )
                    }
                }
                .padding(14)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Beschreibung", icon: "text.alignleft")
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
                .foregroundStyle(workout.sport.color.opacity(0.85))
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

    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Time bar

struct TimeBar: View {
    let label: String
    let seconds: Int
    let total: Double
    let color: Color
    var showPercent: Bool = false

    private var fraction: Double { min(1.0, Double(seconds) / total) }

    private var formatted: String {
        let m = seconds / 60; let s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                        .frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.85))
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
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
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
                HStack {
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
                    .font(.caption).foregroundStyle(.secondary)

                if let inst = source.institution {
                    Label(inst, systemImage: "building.columns")
                        .font(.caption).foregroundStyle(.tertiary)
                }

                if let doi = source.doi,
                   let url = URL(string: "https://doi.org/\(doi)") {
                    Link(destination: url) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.right.square").font(.caption2)
                            Text("DOI: \(doi)").font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(Color.mutedBlue.opacity(0.85))
                    }
                } else if let urlString = source.url,
                          let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.right.square").font(.caption2)
                            Text("Quelle öffnen").font(.caption)
                        }
                        .foregroundStyle(Color.mutedBlue.opacity(0.85))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mutedBlue.opacity(0.25)))
        }
    }

    private var sourceTypeBadge: some View {
        let (icon, label): (String, String) = switch source.type {
        case "paper":  ("doc.text",       "Paper")
        case "book":   ("book.closed",    "Buch")
        case "thesis": ("graduationcap",  "Dissertation")
        default:       ("person.fill",    "Coaching")
        }
        return Label(label, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.mutedBlue)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.mutedBlue.opacity(0.10), in: Capsule())
    }
}

// MARK: - FIT Download Button

struct FITDownloadButton: View {
    let workout: Workout
    @State private var isGenerating = false
    @State private var fitFileURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Button { generateAndShare() } label: {
            if isGenerating {
                ProgressView().controlSize(.small).tint(.white)
            } else {
                Label("Download .FIT", systemImage: "square.and.arrow.down")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(workout.sport.color)
        .disabled(isGenerating)
        .alert("Fehler", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unbekannter Fehler")
        }
        #if os(iOS)
        .sheet(isPresented: $showShare) {
            if let url = fitFileURL {
                ShareSheet(url: url)
            }
        }
        #endif
    }

    private func generateAndShare() {
        isGenerating = true
        Task.detached(priority: .userInitiated) {
            do {
                let data = WorkoutToFIT.encode(workout)
                guard !data.isEmpty else { throw FITError.encodingFailed }
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(workout.id).fit")
                try data.write(to: url)
                await MainActor.run {
                    isGenerating = false
                    #if os(macOS)
                    savePanelMacOS(url: url)
                    #else
                    fitFileURL = url
                    showShare = true
                    #endif
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    #if os(macOS)
    private func savePanelMacOS(url: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(workout.id).fit"
        panel.allowedContentTypes = [.data]
        panel.message = "Als .fit-Datei speichern für Garmin / Wahoo / Zwift"
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: url, to: dest)
        }
    }
    #endif
}

private enum FITError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "FIT-Datei konnte nicht erstellt werden." }
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
