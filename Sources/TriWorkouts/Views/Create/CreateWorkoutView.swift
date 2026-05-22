import SwiftUI

// MARK: - Draft types

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
        self.intensity = intensity
        self.minutes = minutes
        self.seconds = seconds
        self.zone = zone
        self.stepDescription = description
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
        WorkoutStep(
            id: index,
            intensity: intensity,
            durationSeconds: durationSeconds,
            targetType: zone != nil ? .powerZone : .open,
            zone: zone,
            targetZoneNumber: nil,
            powerLowPercent: nil,
            powerHighPercent: nil,
            description: stepDescription.isEmpty ? intensity.displayName : stepDescription,
            repeatCount: nil
        )
    }
}

// MARK: - Create view

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

    // MARK: Computed training metrics

    private var totalSeconds: Int { steps.reduce(0) { $0 + $1.durationSeconds } }

    private var computedIF: Double {
        let total = Double(totalSeconds)
        guard total > 0 else { return 0.0 }
        let weighted = steps.reduce(0.0) {
            $0 + ($1.zone?.ifValue ?? $1.intensity.baseIF) * Double($1.durationSeconds)
        }
        return (weighted / total * 100).rounded() / 100
    }

    private var computedTSS: Int {
        let hours = Double(totalSeconds) / 3600.0
        return Int((hours * computedIF * computedIF * 100).rounded())
    }

    private var previewSteps: [WorkoutStep] {
        steps.enumerated().map { idx, d in d.toWorkoutStep(index: idx) }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !steps.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                stepsSection
                if !steps.isEmpty { previewSection }
                metricsSection
                detailsSection
            }
            .scrollContentBackground(.hidden)
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
        .frame(minWidth: 620, minHeight: 680)
        #endif
        .sheet(isPresented: $showStepEditor) {
            let existing = editingStepID.flatMap { id in steps.first(where: { $0.id == id }) }
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

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("Grundinfo") {
            TextField("Name", text: $name)

            Picker("Sportart", selection: $sport) {
                ForEach(Sport.allCases, id: \.self) { s in
                    Label(s.displayName, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags").font(.caption).foregroundStyle(.secondary)
                TagToggleGrid(selected: $selectedTags)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var stepsSection: some View {
        Section {
            if steps.isEmpty {
                Text("Noch keine Schritte hinzugefügt")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ForEach(steps) { step in
                    DraftStepRow(step: step) {
                        editingStepID = step.id
                        showStepEditor = true
                    }
                }
                .onDelete { steps.remove(atOffsets: $0) }
                .onMove  { steps.move(fromOffsets: $0, toOffset: $1) }
            }

            Button {
                editingStepID = nil
                showStepEditor = true
            } label: {
                Label("Schritt hinzufügen", systemImage: "plus.circle.fill")
                    .foregroundStyle(Color.orange)
            }
        } header: {
            HStack {
                Text("Schritte (\(steps.count))")
                Spacer()
                #if os(iOS)
                EditButton().font(.caption)
                #endif
            }
        } footer: {
            if !steps.isEmpty {
                let m = totalSeconds / 60
                Text("Gesamtdauer: \(m >= 60 ? "\(m/60)h \(m%60)min" : "\(m) min")")
            }
        }
    }

    // Live interval profile chart
    private var previewSection: some View {
        Section("Vorschau") {
            IntervalChartView(steps: previewSteps, totalDuration: totalSeconds)
                .frame(minHeight: 160)
                .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        }
    }

    // Auto-computed metrics (read-only)
    @ViewBuilder
    private var metricsSection: some View {
        if !steps.isEmpty {
            Section {
                LabeledContent("IF (Intensitätsfaktor)") {
                    Text(String(format: "%.2f", computedIF))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                LabeledContent("TSS") {
                    Text("\(computedTSS)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Berechnete Werte")
            } footer: {
                Text("Automatisch aus Zonen und Dauer berechnet")
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Autor", text: $authorName)
            TextField("Beschreibung", text: $workoutDescription, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Save

    private func save() {
        let workoutSteps = steps.enumerated().map { idx, d in d.toWorkoutStep(index: idx) }
        let total = workoutSteps.reduce(0) { $0 + $1.durationSeconds }
        let workout = Workout(
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
        )
        store.addWorkout(workout)
        dismiss()
    }
}

// MARK: - Draft step row

private struct DraftStepRow: View {
    let step: DraftStep
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(step.zone?.color ?? step.intensityColor)
                    .frame(width: 10, height: 10)

                Text(step.intensity.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(step.intensityColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(step.intensityColor.opacity(0.12), in: Capsule())

                if let zone = step.zone {
                    Text("\(zone.rawValue) · \(zone.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(step.formattedDuration)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag toggle grid

private struct TagToggleGrid: View {
    @Binding var selected: Set<WorkoutTag>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(WorkoutTag.allCases, id: \.self) { tag in
                let on = selected.contains(tag)
                Button {
                    if on { selected.remove(tag) } else { selected.insert(tag) }
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
                .animation(.easeOut(duration: 0.1), value: on)
            }
        }
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
                        ForEach([StepIntensity.warmup, .work, .rest, .cooldown], id: \.self) { i in
                            Text(i.displayName).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Dauer") {
                    Stepper(value: $draft.minutes, in: 0...180) {
                        LabeledContent("Minuten") {
                            Text("\(draft.minutes)")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Stepper(value: $draft.seconds, in: 0...55, step: 5) {
                        LabeledContent("Sekunden") {
                            Text("\(draft.seconds)")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
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
                        Button {
                            draft.zone = zone
                        } label: {
                            HStack(spacing: 10) {
                                Circle().fill(zone.color).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(zone.rawValue) · \(zone.name)").foregroundStyle(.primary)
                                    Text(zone.ftpRange).font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if draft.zone == zone {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(zone.color)
                                        .fontWeight(.semibold)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.durationSeconds <= 0)
                }
            }
        }
    }
}
