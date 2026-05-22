import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Hero
                heroSection

                // Stats grid
                statsGrid

                // Interval chart
                IntervalChartView(
                    steps: workout.steps,
                    totalDuration: workout.totalDurationSeconds
                )

                // Step table
                IntervalTableView(steps: workout.steps)

                // Description
                descriptionSection

                // Author & source
                authorSection

                if let source = workout.source {
                    SourceSection(source: source)
                }

                Spacer(minLength: 40)
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

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: workout.sport.icon)
                    .font(.title3)
                    .foregroundStyle(workout.sport.color)
                Text(workout.sport.displayName)
                    .font(.headline)
                    .foregroundStyle(workout.sport.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(workout.sport.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            FlexTagRow(tags: workout.tags)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "clock.fill",     label: "Total",     value: workout.formattedDuration, color: .secondary)
            StatCard(icon: "bolt.fill",      label: "TSS",       value: "\(workout.tss)",          color: .orange)
            StatCard(icon: "waveform.path",  label: "IF",        value: String(format: "%.2f", workout.intensityFactor), color: workout.sport.color)
            StatCard(icon: "repeat",         label: "Intervals", value: "\(workout.intervalCount)", color: .blue)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(workout.description)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
    }

    private var authorSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.appCard, in: Circle())
                .overlay(Circle().stroke(Color.appBorder))
            VStack(alignment: .leading, spacing: 2) {
                Text("Author")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(workout.author)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Supporting views

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
    }
}

private struct FlexTagRow: View {
    let tags: [WorkoutTag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
            }
        }
    }
}

struct SourceSection: View {
    let source: WorkoutSource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Scientific Source", systemImage: "graduationcap.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(source.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(source.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label("\(source.year)", systemImage: "calendar")
                    if let inst = source.institution {
                        Label(inst, systemImage: "building.columns")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)

                if let doi = source.doi {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("DOI: \(doi)")
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.blue.opacity(0.8))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - FIT Download Button

struct FITDownloadButton: View {
    let workout: Workout
    @State private var isGenerating = false
    @State private var fitFileURL: URL?
    @State private var showShare = false

    var body: some View {
        Button {
            generateAndShare()
        } label: {
            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("Download .FIT", systemImage: "square.and.arrow.down")
            }
        }
        #if os(iOS)
        .buttonStyle(.borderedProminent)
        .tint(workout.sport.color)
        .sheet(isPresented: $showShare) {
            if let url = fitFileURL {
                ShareSheet(url: url)
            }
        }
        #else
        .buttonStyle(.borderedProminent)
        .tint(workout.sport.color)
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
                fitFileURL = url
                showShare = true
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
