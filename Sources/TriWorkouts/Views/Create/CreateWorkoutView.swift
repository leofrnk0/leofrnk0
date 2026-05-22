import SwiftUI

// MARK: - Draft step model

private struct DraftStep: Identifiable {
    let id: String
    var intensity: StepIntensity
    var minutes: Int
    var seconds: Int
    var zone: PowerZone?
    var stepDescription: String

    init(intensity: StepIntensity = .work, minutes: Int = 5, seconds: Int = 0,
         zone: PowerZone? = .z3, description: String = "") {
        id = UUID().uuidString
        self.intensity = intensity; self.minutes = minutes
        self.seconds = seconds; self.zone = zone; self.stepDescription = description
    }

    var durationSeconds: Int { max(1, minutes * 60 + seconds) }

    var formattedDuration: String {
        let m = durationSeconds / 60; let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    var intensityColor: Color {
        switch intensity {
        case .warmup:   .blue
        case .work:     .orange
        case .rest:     Color(white: 0.5)
        case .cooldown: .cyan
        }
    }

    func toWorkoutStep(index: Int) -> WorkoutStep {
        WorkoutStep(id: index, intensity: intensity, durationSeconds: durationSeconds,
                    targetType: zone != nil ? .powerZone : .open, zone: zone,
                    targetZoneNumber: nil, powerLowPercent: nil, powerHighPercent: nil,
                    description: stepDescription.isEmpty ? intensity.displayName : stepDescription,
                    repeatCount: nil)
    }
}

// MARK: - Main view

struct CreateWorkoutView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sport: Sport = .cycling
    @State private var selectedTags: Set<WorkoutTag> = []
    @State private var authorName = ""
    @State private var workoutDescription = ""
    @State private var steps: [DraftStep] = []
    @State private var editingStepID: String? = nil
    @State private var showStepEditor = false

    // MARK: Computed metrics

    private var totalSeconds: Int { steps.reduce(0) { $0 + $1.durationSeconds } }

    private var computedIF: Double {
        let total = Double(totalSeconds)
        guard total > 0 else { return 0.0 }
        let w = steps.reduce(0.0) { $0 + ($1.zone?.ifValue ?? $1.intensity.baseIF) * Double($1.durationSeconds) }
        return (w / total * 100).rounded() / 100
    }

    private var computedTSS: Int {
        Int((Double(totalSeconds) / 3600 * computedIF * computedIF * 100).rounded())
    }

    private var previewSteps: [WorkoutStep] {
        steps.enumerated().map { $1.toWorkoutStep(index: $0) }
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !steps.isEmpty }

    private var formattedTotal: String {
        let m = totalSeconds / 60
        return m >= 60 ? "\(m/60)h \(m%60)min" : "\(m) min"
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            mainContent
                .background(Color.appBackground)
                .navigationTitle("Workout erstellen")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") { save() }
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 580)
        #endif
        .sheet(isPresented: $showStepEditor) {
            let existing = editingStepID.flatMap { id in steps.first { $0.id == id } }
            StepEditorSheet(draft: existing ?? DraftStep(), isNew: existing == nil) { saved in
                if let id = editingStepID, let idx = steps.firstIndex(where: { $0.id == id }) {
                    steps[idx] = saved
                } else {
                    steps.append(saved)
                }
                editingStepID = nil
            }
        }
    }

    // MARK: Layout

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            // Left column: metadata
            ScrollView {
                VStack(spacing: 14) {
                    nameField
                    sportPicker
                    tagSection
                    Divider().background(Color.appBorder)
                    detailsFields
                }
                .padding(20)
            }
            .frame(width: 280)
            .background(Color.appCard)

            Divider()

            // Right column: steps + preview + metrics
            ScrollView {
                VStack(spacing: 14) {
                    stepsSection
                    if !steps.isEmpty {
                        previewCard
                        metricsRow
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
        }
        #else
        ScrollView {
            VStack(spacing: 14) {
                nameField
                sportPicker
                tagSection
                stepsSection
                if !steps.isEmpty {
                    previewCard
                    metricsRow
                }
                detailsFields
            }
            .padding(16)
        }
        #endif
    }

    // MARK: - Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Name", systemImage: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            TextField("Workout-Name", text: $name)
                .font(.title3.weight(.semibold))
                .padding(14)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(name.isEmpty ? Color.appBorder : sport.color.opacity(0.6), lineWidth: 1.5)
                )
        }
    }

    // MARK: - Sport picker

    private var sportPicker: some View {
        HStack(spacing: 8) {
            ForEach(Sport.allCases, id: \.self) { s in
                Button { withAnimation(.easeOut(duration: 0.15)) { sport = s } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: s.icon).font(.title3.weight(.semibold))
                        Text(s.displayName).font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(sport == s ? .white : s.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        sport == s ? s.color : s.color.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 7)], spacing: 7) {
                ForEach(WorkoutTag.allCases, id: \.self) { tag in
                    let on = selectedTags.contains(tag)
                    Button {
                        withAnimation(.easeOut(duration: 0.1)) {
                            if on { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                        }
                    } label: {
                        Text(tag.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(on ? .white : tag.color)
                            .lineLimit(1)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                            .background(on ? tag.color : tag.color.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Schritte (\(steps.count))", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    editingStepID = nil
                    showStepEditor = true
                } label: {
                    Label("Hinzufügen", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            if steps.isEmpty {
                emptyStepsPlaceholder
            } else {
                stepList
            }
        }
    }

    private var emptyStepsPlaceholder: some View {
        Button {
            editingStepID = nil
            showStepEditor = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text("Ersten Schritt hinzufügen")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7]))
                    .foregroundStyle(Color.appBorder)
            )
        }
        .buttonStyle(.plain)
    }

    private var stepList: some View {
        List {
            ForEach(steps) { step in
                StepCardRow(step: step) {
                    editingStepID = step.id
                    showStepEditor = true
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
            }
            .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
            .onDelete { steps.remove(atOffsets: $0) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        #if os(iOS)
        // Always show drag handles without needing to tap Edit
        .environment(\.editMode, .constant(.active))
        #endif
        .frame(height: CGFloat(steps.count) * stepRowHeight + 4)
    }

    private var stepRowHeight: CGFloat {
        #if os(macOS)
        return 46
        #else
        return 62
        #endif
    }

    // MARK: - Preview chart

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Vorschau", systemImage: "waveform.path.ecg")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            IntervalChartView(steps: previewSteps, totalDuration: totalSeconds)
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
    }

    // MARK: - Metrics row

    private var metricsRow: some View {
        HStack(spacing: 8) {
            MetricPill(value: String(format: "%.2f", computedIF), label: "IF",    color: sport.color)
            MetricPill(value: "\(computedTSS)",                   label: "TSS",   color: .orange)
            MetricPill(value: formattedTotal,                     label: "Gesamt",color: .secondary)
        }
    }

    // MARK: - Details

    private var detailsFields: some View {
        VStack(spacing: 10) {
            Label("Details", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Autor", text: $authorName)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))

            TextField("Beschreibung (optional)", text: $workoutDescription, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
        }
    }

    // MARK: - Save

    private func save() {
        let workoutSteps = steps.enumerated().map { $1.toWorkoutStep(index: $0) }
        let total = workoutSteps.reduce(0) { $0 + $1.durationSeconds }
        store.addWorkout(Workout(
            id: "user-\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            sport: sport,
            tags: Array(selectedTags),
            totalDurationSeconds: total,
            tss: computedTSS,
            intensityFactor: computedIF,
            description: workoutDescription.isEmpty ? name : workoutDescription,
            author: authorName.isEmpty ? "Eigenes Workout" : authorName,
            steps: workoutSteps,
            source: nil
        ))
        dismiss()
    }
}

// MARK: - Step card row (used inside List)

private struct StepCardRow: View {
    let step: DraftStep
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Zone color stripe
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.zone?.color ?? step.intensityColor)
                    .frame(width: 4)
                    .padding(.vertical, 6)

                HStack(spacing: 10) {
                    // Intensity badge
                    Text(step.intensity.displayName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(step.intensityColor)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(step.intensityColor.opacity(0.15), in: Capsule())

                    // Zone label
                    if let zone = step.zone {
                        Text("\(zone.rawValue) · \(zone.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Offen").font(.caption).foregroundStyle(.tertiary)
                    }

                    Spacer(minLength: 4)

                    // Duration
                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Metric pill

private struct MetricPill: View {
    let value: String; let label: String; let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.callout, design: .monospaced).weight(.bold))
                .foregroundStyle(color == .secondary ? .primary : color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
    }
}

// MARK: - Step editor sheet

private struct StepEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DraftStep
    let isNew: Bool
    let onSave: (DraftStep) -> Void

    init(draft: DraftStep, isNew: Bool, onSave: @escaping (DraftStep) -> Void) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Intensität") {
                    Picker("", selection: $draft.intensity) {
                        ForEach([StepIntensity.warmup, .work, .rest, .cooldown], id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Dauer") {
                    Stepper(value: $draft.minutes, in: 0...180) {
                        LabeledContent("Minuten") {
                            Text("\(draft.minutes)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    Stepper(value: $draft.seconds, in: 0...55, step: 5) {
                        LabeledContent("Sekunden") {
                            Text("\(draft.seconds)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Zone (optional)") {
                    Button {
                        draft.zone = nil
                    } label: {
                        HStack {
                            Text("Keine Zone").foregroundStyle(.primary)
                            Spacer()
                            if draft.zone == nil {
                                Image(systemName: "checkmark").foregroundStyle(.secondary).fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(PowerZone.allCases, id: \.self) { zone in
                        Button { draft.zone = zone } label: {
                            HStack(spacing: 10) {
                                Circle().fill(zone.color).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(zone.rawValue) · \(zone.name)").foregroundStyle(.primary)
                                    Text(zone.ftpRange).font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if draft.zone == zone {
                                    Image(systemName: "checkmark").foregroundStyle(zone.color).fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Beschreibung") {
                    TextField("Optional", text: $draft.stepDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(isNew ? "Schritt hinzufügen" : "Schritt bearbeiten")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { onSave(draft); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(draft.durationSeconds <= 0)
                }
            }
        }
    }
}
