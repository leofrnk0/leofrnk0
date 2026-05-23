import SwiftUI
#if os(macOS)
import AppKit
#endif

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(AppSettings.self)  private var settings
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss)         private var dismiss
    @State private var showEdit          = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sportHeader
                IntervalChartView(steps: workout.steps, totalDuration: workout.totalDurationSeconds)
                mainStats
                zoneDistribution
                IntervalTableView(steps: workout.steps, sport: workout.sport)
                equipmentSection
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
            if settings.isAdmin {
                ToolbarItem(placement: .secondaryAction) {
                    Button { showEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                if store.isUserWorkout(workout) {
                    ToolbarItem(placement: .secondaryAction) {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ExportMenuButton(workout: workout)
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { store.deleteWorkout(workout); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(""\(workout.name)" will be permanently deleted.")
        }
        .sheet(isPresented: $showEdit) {
            CreateWorkoutView(editingWorkout: workout)
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
        }
    }

    // MARK: - Sport header

    private var sportHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: workout.sport.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(workout.sport.color)
                Text(workout.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
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
        case ..<60:    (Color.mutedBlue,   "Easy")
        case 60..<85:  (Color.mutedGreen,  "Moderate")
        case 85..<105: (Color.mutedOrange, "Hard")
        default:       (Color.mutedRed,    "Very Hard")
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
            StatCard(icon: "clock.fill",    label: "Total",     value: workout.formattedDuration,                        color: .secondary)
            StatCard(icon: "bolt.fill",     label: "TSS",       value: "\(workout.tss)",                                 color: Color.mutedOrange)
            StatCard(icon: "waveform.path", label: "IF",        value: String(format: "%.2f", workout.intensityFactor),  color: workout.sport.color)
            StatCard(icon: "repeat",        label: "Intervals", value: "\(workout.intervalCount)",                        color: Color.mutedBlue)
        }
    }

    // MARK: - Time breakdown

    private var timeBreakdownData: [(label: String, seconds: Int, color: Color)] {
        [
            ("Work",       workout.steps.filter { $0.intensity == .work     }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedOrange),
            ("Recovery",   workout.steps.filter { $0.intensity == .rest     }.reduce(0) { $0 + $1.durationSeconds }, Color(white: 0.40)),
            ("Warm-up",    workout.steps.filter { $0.intensity == .warmup   }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedBlue),
            ("Cool-down",  workout.steps.filter { $0.intensity == .cooldown }.reduce(0) { $0 + $1.durationSeconds }, Color.mutedCyan),
        ].filter { $0.seconds > 0 }
    }

    private var timeBreakdown: some View {
        let data = timeBreakdownData
        let total = Double(max(1, workout.totalDurationSeconds))
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Training Time Breakdown", icon: "chart.bar.fill")
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
                sectionLabel("Zone Distribution", icon: "square.3.layers.3d")
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

    // MARK: - Equipment

    @ViewBuilder
    private var equipmentSection: some View {
        let allEquipment = Array(Set(workout.steps.flatMap { $0.equipment ?? [] }))
            .sorted { $0.rawValue < $1.rawValue }
        if !allEquipment.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Equipment needed", icon: "bag.fill")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(allEquipment, id: \.self) { item in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.mutedCyan.opacity(0.12))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: item.icon)
                                        .font(.title2)
                                        .foregroundStyle(Color.mutedCyan)
                                }
                                Text(item.rawValue)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 72)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(14)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mutedCyan.opacity(0.20)))
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Description", icon: "text.alignleft")
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
                Text("Author").font(.caption).foregroundStyle(.tertiary)
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
            Label("Scientific Source", systemImage: "graduationcap.fill")
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
                            Text("Open Source").font(.caption)
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
        case "book":   ("book.closed",    "Book")
        case "thesis": ("graduationcap",  "Thesis")
        default:       ("person.fill",    "Coaching")
        }
        return Label(label, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.mutedBlue)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.mutedBlue.opacity(0.10), in: Capsule())
    }
}

// MARK: - Export format

enum ExportFormat: CaseIterable, Identifiable {
    case fit, zwo, mrc

    var id: Self { self }

    var label: String {
        switch self {
        case .fit: "Garmin / Wahoo (.fit)"
        case .zwo: "Zwift (.zwo)"
        case .mrc: "TrainerRoad (.mrc)"
        }
    }

    var icon: String {
        switch self {
        case .fit: "bolt.fill"
        case .zwo: "bicycle"
        case .mrc: "chart.xyaxis.line"
        }
    }

    var ext: String {
        switch self {
        case .fit: "fit"
        case .zwo: "zwo"
        case .mrc: "mrc"
        }
    }

    var saveDescription: String {
        switch self {
        case .fit: "Save workout for Garmin / Wahoo / Zwift"
        case .zwo: "Save Zwift workout"
        case .mrc: "Save TrainerRoad workout"
        }
    }

    func encode(_ workout: Workout) throws -> Data {
        let data: Data
        switch self {
        case .fit:
            data = WorkoutToFIT.encode(workout)
        case .zwo:
            data = WorkoutToZWO.encode(workout)
        case .mrc:
            data = WorkoutToMRC.encode(workout)
        }
        guard !data.isEmpty else { throw ExportError.encodingFailed }
        return data
    }
}

private enum ExportError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "File could not be created." }
}

// MARK: - Export menu button

struct ExportMenuButton: View {
    let workout: Workout
    @State private var isGenerating = false
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Menu {
            ForEach(ExportFormat.allCases) { fmt in
                Button { export(fmt) } label: {
                    Label(fmt.label, systemImage: fmt.icon)
                }
            }
        } label: {
            if isGenerating {
                ProgressView().controlSize(.small).tint(.white)
            } else {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.borderedProminent)
        .tint(workout.sport.color)
        .disabled(isGenerating)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        #if os(iOS)
        .sheet(isPresented: $showShare) {
            if let url = exportURL { ShareSheet(url: url) }
        }
        #endif
    }

    private func export(_ format: ExportFormat) {
        isGenerating = true
        Task.detached(priority: .userInitiated) {
            do {
                let data = try format.encode(workout)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(workout.id).\(format.ext)")
                try data.write(to: url)
                await MainActor.run {
                    isGenerating = false
                    #if os(macOS)
                    savePanelMacOS(url: url, format: format)
                    #else
                    exportURL = url
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
    private func savePanelMacOS(url: URL, format: ExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(workout.id).\(format.ext)"
        panel.allowedContentTypes = [.data]
        panel.message = format.saveDescription
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
