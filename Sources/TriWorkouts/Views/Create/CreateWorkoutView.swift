import SwiftUI

// MARK: - Draft models

fileprivate enum DurationMode { case time, distance }

fileprivate struct DraftStep: Identifiable {
    let id: String
    var intensity: StepIntensity
    var minutes: Int
    var seconds: Int
    var zone: PowerZone?
    var stepDescription: String
    var durationMode: DurationMode = .time
    var distanceMeters: Int = 400
    var swimEquipment: Set<SwimEquipment> = []
    var ftpPercent: Double? = nil

    init(intensity: StepIntensity = .work, minutes: Int = 5, seconds: Int = 0,
         zone: PowerZone? = .z3, description: String = "") {
        id = UUID().uuidString
        self.intensity = intensity; self.minutes = minutes
        self.seconds = seconds; self.zone = zone; self.stepDescription = description
    }

    init(from step: WorkoutStep) {
        id = UUID().uuidString
        intensity = step.intensity
        minutes = step.durationSeconds / 60
        seconds = step.durationSeconds % 60
        zone = step.zone
        stepDescription = step.description
        if let d = step.distanceMeters {
            durationMode = .distance
            distanceMeters = d
        }
        swimEquipment = Set(step.equipment ?? [])
        ftpPercent = step.ftpPercent
    }

    var durationSeconds: Int { max(1, minutes * 60 + seconds) }

    var formattedDuration: String {
        if durationMode == .distance {
            return distanceMeters >= 1000
                ? String(format: "%.1f km", Double(distanceMeters) / 1000.0)
                : "\(distanceMeters) m"
        }
        let m = durationSeconds / 60; let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    var intensityColor: Color {
        switch intensity {
        case .warmup:   Color.mutedBlue
        case .work:     Color.mutedOrange
        case .rest:     Color(white: 0.40)
        case .cooldown: Color.mutedCyan
        }
    }

    func estimatedSeconds(sport: Sport) -> Int {
        switch sport {
        case .swimming: return max(10, distanceMeters * 72 / 100)   // ~1:12/100m
        case .running:  return max(30, distanceMeters * 300 / 1000) // ~5min/km
        case .cycling:  return max(30, distanceMeters * 180 / 1000) // ~3min/km
        }
    }

    func toWorkoutStep(index: Int, sport: Sport) -> WorkoutStep {
        let secs = durationMode == .time ? durationSeconds : estimatedSeconds(sport: sport)
        return WorkoutStep(id: index, intensity: intensity, durationSeconds: secs,
                    targetType: zone != nil || ftpPercent != nil ? .powerZone : .open, zone: zone,
                    targetZoneNumber: nil, powerLowPercent: ftpPercent, powerHighPercent: ftpPercent,
                    description: stepDescription.isEmpty ? intensity.displayName : stepDescription,
                    repeatCount: nil,
                    distanceMeters: durationMode == .distance ? distanceMeters : nil,
                    equipment: swimEquipment.isEmpty ? nil : Array(swimEquipment))
    }
}

fileprivate enum DraftItem: Identifiable {
    case step(DraftStep)
    case repeatBlock(id: String, count: Int, steps: [DraftStep])

    var id: String {
        switch self {
        case .step(let s):                   return s.id
        case .repeatBlock(let id, _, _): return id
        }
    }

    var totalDurationSeconds: Int {
        switch self {
        case .step(let s):                       return s.durationSeconds
        case .repeatBlock(_, let c, let ss): return ss.reduce(0) { $0 + $1.durationSeconds } * c
        }
    }
}

// MARK: - Main create view

struct CreateWorkoutView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let editingWorkout: Workout?

    @State private var name: String
    @State private var sport: Sport
    @State private var selectedTags: Set<WorkoutTag>
    @State private var authorName: String
    @State private var workoutDescription: String
    @State private var items: [DraftItem]

    @State private var editingItemID: String? = nil
    @State private var showStepEditor = false
    @State private var showRepeatEditor = false

    init(editingWorkout: Workout? = nil) {
        self.editingWorkout = editingWorkout
        if let w = editingWorkout {
            _name               = State(initialValue: w.name)
            _sport              = State(initialValue: w.sport)
            _selectedTags       = State(initialValue: Set(w.tags))
            _authorName         = State(initialValue: w.author)
            _workoutDescription = State(initialValue: w.description)
            _items              = State(initialValue: w.steps.map { .step(DraftStep(from: $0)) })
        } else {
            _name               = State(initialValue: "")
            _sport              = State(initialValue: .cycling)
            _selectedTags       = State(initialValue: [])
            _authorName         = State(initialValue: "")
            _workoutDescription = State(initialValue: "")
            _items              = State(initialValue: [])
        }
    }

    // MARK: Computed

    private var totalSeconds: Int { items.reduce(0) { $0 + $1.totalDurationSeconds } }

    private var flattenedSteps: [WorkoutStep] {
        var result: [WorkoutStep] = []
        var idx = 0
        for item in items {
            switch item {
            case .step(let s):
                result.append(s.toWorkoutStep(index: idx, sport: sport)); idx += 1
            case .repeatBlock(_, let c, let ss):
                for _ in 0..<c { for s in ss { result.append(s.toWorkoutStep(index: idx, sport: sport)); idx += 1 } }
            }
        }
        return result
    }

    private var computedIF: Double {
        let total = Double(totalSeconds)
        guard total > 0 else { return 0.0 }
        let w = flattenedSteps.reduce(0.0) {
            let stepIF = $1.zone?.ifValue ?? $1.ftpPercent.map { $0 / 100.0 } ?? $1.intensity.baseIF
            return $0 + stepIF * Double($1.durationSeconds)
        }
        return (w / total * 100).rounded() / 100
    }

    private var computedTSS: Int {
        Int((Double(totalSeconds) / 3600 * computedIF * computedIF * 100).rounded())
    }

    private var formattedTotal: String {
        let m = totalSeconds / 60
        return m >= 60 ? "\(m/60)h \(m%60)min" : "\(m) min"
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty }

    // MARK: Body

    var body: some View {
        NavigationStack {
            mainContent
                .background(Color.appBackground)
                .navigationTitle(editingWorkout == nil ? "Create Workout" : "Edit Workout")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .fontWeight(.semibold).disabled(!isValid)
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 580)
        #endif
        // Single step editor
        .sheet(isPresented: $showStepEditor) {
            StepEditorSheet(draft: existingStep() ?? DraftStep(), isNew: existingStep() == nil, sport: sport) { saved in
                if let id = editingItemID, let idx = items.firstIndex(where: { $0.id == id }) {
                    items[idx] = .step(saved)
                } else { items.append(.step(saved)) }
                editingItemID = nil
            }
        }
        // Repeat block editor
        .sheet(isPresented: $showRepeatEditor) {
            let block = existingBlock()
            RepeatBlockEditorSheet(count: block?.count ?? 3, steps: block?.steps ?? [], isNew: block == nil, sport: sport) { count, steps in
                if let id = editingItemID, let idx = items.firstIndex(where: { $0.id == id }) {
                    items[idx] = .repeatBlock(id: id, count: count, steps: steps)
                } else { items.append(.repeatBlock(id: UUID().uuidString, count: count, steps: steps)) }
                editingItemID = nil
            }
        }
    }

    private func existingStep() -> DraftStep? {
        guard let id = editingItemID,
              case .step(let s) = items.first(where: { $0.id == id }) else { return nil }
        return s
    }

    private func existingBlock() -> (count: Int, steps: [DraftStep])? {
        guard let id = editingItemID,
              case .repeatBlock(_, let c, let ss) = items.first(where: { $0.id == id }) else { return nil }
        return (c, ss)
    }

    // MARK: Layout

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) { nameField; sportPicker; tagSection; Divider(); detailsFields }
                    .padding(20)
            }
            .frame(width: 280)
            .background(Color.appCard)

            Divider()

            ScrollView {
                VStack(spacing: 14) {
                    if !items.isEmpty { previewCard }
                    stepsSection
                    if !items.isEmpty { metricsRow }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
        }
        #else
        ScrollView {
            VStack(spacing: 14) {
                nameField; sportPicker; tagSection
                if !items.isEmpty { previewCard }
                stepsSection
                if !items.isEmpty { metricsRow }
                detailsFields
            }
            .padding(16)
        }
        #endif
    }

    // MARK: - Sub-views

    private var nameField: some View {
        TextField("Workout Name", text: $name)
            .font(.title3.weight(.semibold))
            .padding(14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(name.isEmpty ? Color.appBorder : sport.color.opacity(0.6), lineWidth: 1.5))
    }

    private var sportPicker: some View {
        HStack(spacing: 8) {
            ForEach(Sport.allCases, id: \.self) { s in
                Button { withAnimation(.easeOut(duration: 0.15)) { sport = s } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: s.icon).font(.title3.weight(.semibold))
                        Text(s.displayName).font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(sport == s ? .white : s.color)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(sport == s ? s.color : s.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
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

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Preview", systemImage: "waveform.path.ecg")
                .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            IntervalChartView(steps: flattenedSteps, totalDuration: totalSeconds)
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Steps (\(items.count))", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                addMenu
            }

            if items.isEmpty {
                Button { editingItemID = nil; showStepEditor = true } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle").font(.system(size: 36)).foregroundStyle(.tertiary)
                        Text("Add First Step").font(.subheadline.weight(.medium)).foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 32)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7]))
                        .foregroundStyle(Color.appBorder))
                }
                .buttonStyle(.plain)
            } else {
                List {
                    ForEach(items) { item in
                        itemRow(item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                    }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { items.remove(atOffsets: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                #if os(iOS)
                .environment(\.editMode, .constant(.active))
                #endif
                .frame(height: CGFloat(items.count) * rowHeight + 4)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: DraftItem) -> some View {
        switch item {
        case .step(let step):
            StepCardRow(step: step) {
                editingItemID = item.id
                showStepEditor = true
            }
        case .repeatBlock(_, let count, let steps):
            RepeatBlockRow(count: count, steps: steps) {
                editingItemID = item.id
                showRepeatEditor = true
            }
        }
    }

    private var rowHeight: CGFloat {
        #if os(macOS)
        return 46
        #else
        return 62
        #endif
    }

    private var addMenu: some View {
        Menu {
            Button { editingItemID = nil; showStepEditor = true } label: {
                Label("Single Step", systemImage: "plus.circle")
            }
            Button { editingItemID = nil; showRepeatEditor = true } label: {
                Label("Repeat Block", systemImage: "repeat")
            }
        } label: {
            Label("Add", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.mutedOrange)
        }
        .menuStyle(.borderlessButton)
    }

    private var metricsRow: some View {
        HStack(spacing: 8) {
            MetricPill(value: String(format: "%.2f", computedIF), label: "IF",    color: sport.color)
            MetricPill(value: "\(computedTSS)",                   label: "TSS",   color: Color.mutedOrange)
            MetricPill(value: formattedTotal,                     label: "Total", color: .secondary)
        }
    }

    private var detailsFields: some View {
        VStack(spacing: 10) {
            Label("Details", systemImage: "info.circle")
                .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Author", text: $authorName)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
            TextField("Description (optional)", text: $workoutDescription, axis: .vertical)
                .lineLimit(3...6).padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
        }
    }

    // MARK: - Save

    private func save() {
        let steps = flattenedSteps
        let indexed = steps.enumerated().map { idx, s in
            WorkoutStep(id: idx, intensity: s.intensity, durationSeconds: s.durationSeconds,
                        targetType: s.targetType, zone: s.zone, targetZoneNumber: nil,
                        powerLowPercent: nil, powerHighPercent: nil, description: s.description,
                        repeatCount: nil, distanceMeters: s.distanceMeters,
                        equipment: s.equipment)
        }
        let total = indexed.reduce(0) { $0 + $1.durationSeconds }
        let workout = Workout(
            id: editingWorkout?.id ?? "user-\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            sport: sport, tags: Array(selectedTags),
            totalDurationSeconds: total, tss: computedTSS, intensityFactor: computedIF,
            description: workoutDescription.isEmpty ? name : workoutDescription,
            author: authorName.isEmpty ? "My Workout" : authorName,
            steps: indexed, source: nil
        )
        if editingWorkout != nil { store.updateWorkout(workout) } else { store.addWorkout(workout) }
        dismiss()
    }
}

// MARK: - Step card row

private struct StepCardRow: View {
    let step: DraftStep; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.zone?.color ?? step.intensityColor)
                    .frame(width: 4).padding(.vertical, 6)
                HStack(spacing: 10) {
                    Text(step.intensity.displayName)
                        .font(.caption2.weight(.bold)).foregroundStyle(step.intensityColor)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(step.intensityColor.opacity(0.15), in: Capsule())
                    if let zone = step.zone {
                        Text("\(zone.rawValue) · \(zone.name)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    } else if let pct = step.ftpPercent {
                        Text("\(Int(pct))% FTP").font(.caption).foregroundStyle(Color.mutedOrange).lineLimit(1)
                    } else {
                        Text("Open").font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 4)
                    Text(step.formattedDuration)
                        .font(.system(.callout, design: .monospaced).weight(.semibold)).foregroundStyle(.primary)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Repeat block row

private struct RepeatBlockRow: View {
    let count: Int; let steps: [DraftStep]; let onTap: () -> Void
    private var total: Int { steps.reduce(0) { $0 + $1.durationSeconds } * count }
    private var formattedTotal: String {
        let m = total / 60; return m >= 60 ? "\(m/60)h \(m%60)min" : "\(m) min"
    }
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                VStack(spacing: 1) {
                    ForEach(steps) { s in Rectangle().fill(s.zone?.color ?? s.intensityColor) }
                }
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(count)×")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(Color.mutedOrange)
                        Text("rounds")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text(formattedTotal)
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.primary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(steps) { s in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(s.zone?.color ?? s.intensityColor)
                                        .frame(width: 7, height: 7)
                                    Text(s.intensity.displayName)
                                        .font(.caption2.weight(.semibold))
                                    Text(s.formattedDuration)
                                        .font(.caption2.monospacedDigit())
                                }
                                .foregroundStyle(s.zone?.color ?? s.intensityColor)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background((s.zone?.color ?? s.intensityColor).opacity(0.12),
                                            in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
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
            Text(value).font(.system(.callout, design: .monospaced).weight(.bold))
                .foregroundStyle(color == .secondary ? .primary : color)
            Text(label).font(.caption2.weight(.medium)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
    }
}

// MARK: - Distance spinner

private struct DistanceSpinner: View {
    @Binding var meters: Int
    private let presets = [25, 50, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1500, 2000, 3000, 5000, 10000]

    private var currentIndex: Int {
        presets.firstIndex(where: { $0 >= meters }) ?? presets.count - 1
    }
    private var formatted: String {
        meters >= 1000 ? String(format: "%.1f km", Double(meters) / 1000.0) : "\(meters) m"
    }

    var body: some View {
        VStack(spacing: 10) {
            Button {
                let i = currentIndex
                if i < presets.count - 1 { meters = presets[i + 1] }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(currentIndex < presets.count - 1 ? Color.mutedOrange : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text(formatted)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .frame(minWidth: 140, alignment: .center)
                .contentTransition(.numericText())

            Button {
                let i = currentIndex
                if i > 0 { meters = presets[i - 1] }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(currentIndex > 0 ? .secondary : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text("distance").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            if !presets.contains(meters) { meters = 400 }
        }
    }
}

// MARK: - FTP percent spinner

private struct FTPPercentSpinner: View {
    @Binding var value: Double
    private let step: Double = 5
    private let range: ClosedRange<Double> = 40...150

    var body: some View {
        VStack(spacing: 10) {
            Button { value = min(range.upperBound, value + step) } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value < range.upperBound ? Color.mutedOrange : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text("\(Int(value))%")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .frame(minWidth: 140, alignment: .center)
                .contentTransition(.numericText())

            Button { value = max(range.lowerBound, value - step) } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value > range.lowerBound ? .secondary : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text("% FTP").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Step editor sheet (redesigned, no Form)

fileprivate struct StepEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DraftStep
    let isNew: Bool
    let sport: Sport
    fileprivate let onSave: (DraftStep) -> Void

    fileprivate init(draft: DraftStep, isNew: Bool, sport: Sport, onSave: @escaping (DraftStep) -> Void) {
        _draft = State(initialValue: draft); self.isNew = isNew; self.sport = sport; self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Intensity
                    editorSection("Intensity", icon: "bolt") {
                        HStack(spacing: 8) {
                            ForEach([StepIntensity.warmup, .work, .rest, .cooldown], id: \.self) { i in
                                let on = draft.intensity == i
                                let c = intensityColor(i)
                                Button { withAnimation(.easeOut(duration: 0.15)) { draft.intensity = i } } label: {
                                    VStack(spacing: 5) {
                                        Image(systemName: intensityIcon(i)).font(.title3)
                                        Text(i.displayName).font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(on ? .white : c)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(on ? c : c.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Duration
                    editorSection("Duration", icon: "clock") {
                        Picker("", selection: $draft.durationMode) {
                            Text("Time").tag(DurationMode.time)
                            Text("Distance").tag(DurationMode.distance)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 4)

                        if draft.durationMode == .time {
                            HStack(spacing: 12) {
                                DurationSpinner(value: $draft.minutes, label: "min", range: 0...180, step: 1)
                                DurationSpinner(value: $draft.seconds, label: "sec", range: 0...55, step: 5)
                            }
                        } else {
                            DistanceSpinner(meters: $draft.distanceMeters)
                        }
                    }

                    // Zone
                    editorSection("Zone", icon: "gauge.medium") {
                        if sport == .cycling {
                            Picker("", selection: Binding<Bool>(
                                get: { draft.ftpPercent != nil },
                                set: { newVal in
                                    if newVal {
                                        draft.zone = nil
                                        if draft.ftpPercent == nil { draft.ftpPercent = 75 }
                                    } else {
                                        draft.ftpPercent = nil
                                    }
                                }
                            )) {
                                Text("Zone").tag(false)
                                Text("FTP %").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .padding(.bottom, 4)
                        }

                        if sport == .cycling && draft.ftpPercent != nil {
                            FTPPercentSpinner(value: Binding(
                                get: { draft.ftpPercent ?? 75 },
                                set: { draft.ftpPercent = $0 }
                            ))
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                // "Keine Zone" tile
                                let noZoneOn = draft.zone == nil
                                Button { draft.zone = nil } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "minus.circle").font(.body)
                                        Text("Open").font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(noZoneOn ? .white : .secondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(noZoneOn ? Color(white: 0.3) : Color.appElevated, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .animation(.easeOut(duration: 0.1), value: draft.zone == nil)

                                ForEach(PowerZone.allCases, id: \.self) { zone in
                                    let on = draft.zone == zone
                                    Button { draft.zone = zone } label: {
                                        VStack(spacing: 4) {
                                            Circle().fill(zone.color).frame(width: 10, height: 10)
                                            Text(zone.rawValue).font(.caption.weight(.bold))
                                            Text(zone.name).font(.caption2).lineLimit(1)
                                        }
                                        .foregroundStyle(on ? .white : zone.color)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(on ? zone.color : zone.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeOut(duration: 0.1), value: on)
                                }
                            }
                        }
                    }

                    // Equipment (swimming only)
                    if sport == .swimming {
                        editorSection("Equipment", icon: "bag.fill") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                ForEach(SwimEquipment.allCases, id: \.self) { item in
                                    let on = draft.swimEquipment.contains(item)
                                    Button {
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            if on { draft.swimEquipment.remove(item) }
                                            else  { draft.swimEquipment.insert(item) }
                                        }
                                    } label: {
                                        Label(item.rawValue, systemImage: item.icon)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(on ? .white : Color.mutedCyan)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(on ? Color.mutedCyan : Color.mutedCyan.opacity(0.10),
                                                        in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeOut(duration: 0.1), value: on)
                                }
                            }
                        }
                    }

                    // Description
                    editorSection("Description", icon: "text.alignleft") {
                        TextField("Optional", text: $draft.stepDescription, axis: .vertical)
                            .lineLimit(2...4).padding(12)
                            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(isNew ? "Add Step" : "Edit Step")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSave(draft); dismiss() }
                        .fontWeight(.semibold).disabled(draft.durationSeconds <= 0)
                }
            }
        }
    }

    private func editorSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            content()
        }
    }

    private func intensityColor(_ i: StepIntensity) -> Color {
        switch i { case .warmup: Color.mutedBlue; case .work: Color.mutedOrange; case .rest: Color(white: 0.40); case .cooldown: Color.mutedCyan }
    }
    private func intensityIcon(_ i: StepIntensity) -> String {
        switch i { case .warmup: "sun.horizon.fill"; case .work: "bolt.fill"; case .rest: "pause.circle.fill"; case .cooldown: "wind" }
    }
}

// MARK: - Repeat block editor sheet

fileprivate struct RepeatBlockEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var count: Int
    @State private var innerSteps: [DraftStep]
    let isNew: Bool
    let sport: Sport
    fileprivate let onSave: (Int, [DraftStep]) -> Void

    @State private var editingInnerID: String? = nil
    @State private var showInnerEditor = false

    fileprivate init(count: Int = 3, steps: [DraftStep] = [], isNew: Bool, sport: Sport, onSave: @escaping (Int, [DraftStep]) -> Void) {
        _count = State(initialValue: max(2, count))
        _innerSteps = State(initialValue: steps)
        self.isNew = isNew; self.sport = sport; self.onSave = onSave
    }

    private var roundTotal: Int { innerSteps.reduce(0) { $0 + $1.durationSeconds } }
    private var blockTotal: Int { roundTotal * count }
    private func fmt(_ s: Int) -> String {
        let m = s / 60; return m >= 60 ? "\(m/60)h \(m%60)min" : "\(m) min"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Count spinner
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Repetitions", systemImage: "repeat")
                            .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                        HStack(spacing: 24) {
                            Button { count = max(2, count - 1) } label: {
                                Image(systemName: "minus.circle.fill").font(.largeTitle).foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            Text("\(count)×")
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .frame(maxWidth: .infinity)
                            Button { count = min(30, count + 1) } label: {
                                Image(systemName: "plus.circle.fill").font(.largeTitle).foregroundStyle(Color.mutedOrange)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
                    }

                    // Inner steps
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Steps per Round (\(innerSteps.count))", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            Spacer()
                            Button { editingInnerID = nil; showInnerEditor = true } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(.caption.weight(.semibold)).foregroundStyle(Color.mutedOrange)
                            }
                            .buttonStyle(.plain)
                        }

                        if innerSteps.isEmpty {
                            Button { showInnerEditor = true } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle").font(.title2).foregroundStyle(.tertiary)
                                    Text("Add Step").font(.caption).foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 20)
                                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                    .foregroundStyle(Color.appBorder))
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(spacing: 2) {
                                ForEach(innerSteps) { step in
                                    InnerStepRow(step: step) {
                                        editingInnerID = step.id; showInnerEditor = true
                                    } onDelete: {
                                        innerSteps.removeAll { $0.id == step.id }
                                    }
                                    if step.id != innerSteps.last?.id {
                                        Divider().background(Color.appBorder).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Summary
                    if !innerSteps.isEmpty {
                        HStack(spacing: 12) {
                            VStack(spacing: 3) {
                                Text(fmt(roundTotal)).font(.callout.monospacedDigit().weight(.bold))
                                Text("per round").font(.caption2).foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))

                            VStack(spacing: 3) {
                                Text(fmt(blockTotal)).font(.callout.monospacedDigit().weight(.bold)).foregroundStyle(Color.mutedOrange)
                                Text("Total").font(.caption2).foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(isNew ? "Repeat Block" : "Edit Block")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSave(count, innerSteps); dismiss() }
                        .fontWeight(.semibold).disabled(innerSteps.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showInnerEditor) {
            let existing = editingInnerID.flatMap { id in innerSteps.first { $0.id == id } }
            StepEditorSheet(draft: existing ?? DraftStep(), isNew: existing == nil, sport: sport) { saved in
                if let id = editingInnerID, let idx = innerSteps.firstIndex(where: { $0.id == id }) {
                    innerSteps[idx] = saved
                } else { innerSteps.append(saved) }
                editingInnerID = nil
            }
        }
    }
}

// MARK: - Inner step row (used in RepeatBlockEditorSheet)

private struct InnerStepRow: View {
    let step: DraftStep; let onTap: () -> Void; let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(step.zone?.color ?? step.intensityColor).frame(width: 3).padding(.vertical, 4)
            HStack(spacing: 8) {
                Text(step.intensity.displayName)
                    .font(.caption2.weight(.bold)).foregroundStyle(step.intensityColor)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(step.intensityColor.opacity(0.14), in: Capsule())
                if let z = step.zone {
                    Text("\(z.rawValue)").font(.caption).foregroundStyle(.secondary)
                } else if let pct = step.ftpPercent {
                    Text("\(Int(pct))% FTP").font(.caption).foregroundStyle(Color.mutedOrange)
                }
                Spacer()
                Text(step.formattedDuration).font(.system(.callout, design: .monospaced).weight(.medium))
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color(white: 0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Duration spinner

private struct DurationSpinner: View {
    @Binding var value: Int
    let label: String
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(spacing: 10) {
            Button { value = min(range.upperBound, value + step) } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value < range.upperBound ? Color.mutedOrange : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text("\(value)")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .frame(minWidth: 72, alignment: .center)

            Button { value = max(range.lowerBound, value - step) } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value > range.lowerBound ? .secondary : Color.appBorder)
            }
            .buttonStyle(.plain)

            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
    }
}
