import SwiftUI

struct FilterView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var store = store

        #if os(macOS)
        macOSSidebar
        #else
        // iPad in sidebar column: use sidebar layout (no dismiss button)
        // iPhone as sheet: use sheet layout with Done/Reset header
        if sizeClass == .regular {
            macOSSidebar
        } else {
            iOSSheet
        }
        #endif
    }

    // MARK: - macOS sidebar (always visible, no dismiss needed)

    private var macOSSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Library")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                if store.activeFilterCount > 0 {
                    Button("Reset") { store.clearFilters() }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            filterContent
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appCard)
    }

    // MARK: - iOS sheet (modal, needs dismiss button)

    private var iOSSheet: some View {
        VStack(spacing: 0) {
            // Custom sheet header
            HStack {
                Button("Zurücksetzen") { store.clearFilters() }
                    .font(.callout)
                    .foregroundStyle(store.activeFilterCount > 0 ? .orange : .clear)
                    .disabled(store.activeFilterCount == 0)
                    .animation(.easeOut(duration: 0.15), value: store.activeFilterCount)

                Spacer()

                Text("Filters")
                    .font(.headline)

                Spacer()

                Button("Done") { dismiss() }
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appCard)

            Divider().background(Color.appBorder)

            filterContent
        }
        .background(Color.appBackground)
    }

    // MARK: - Shared filter content

    private var filterContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let activeSports = Sport.allCases.filter { settings.enabledSports.contains($0) }
                if activeSports.count > 1 {
                    FilterSection(title: "Sport") {
                        ForEach(activeSports, id: \.self) { sport in
                            FilterToggleRow(
                                label: sport.displayName,
                                icon: sport.icon,
                                color: sport.color,
                                isOn: store.selectedSports.contains(sport)
                            ) { store.toggleSport(sport) }
                        }
                    }
                }

                FilterSection(title: "Training Type") {
                    ForEach(WorkoutTag.allCases, id: \.self) { tag in
                        FilterToggleRow(
                            label: tag.displayName,
                            icon: nil,
                            color: tag.color,
                            isOn: store.selectedTags.contains(tag)
                        ) { store.toggleTag(tag) }
                    }
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Supporting views

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
            VStack(spacing: 0) { content }
        }
    }
}

private struct FilterToggleRow: View {
    let label: String
    let icon: String?
    let color: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(isOn ? color : .secondary)
                            .frame(width: 20)
                    } else {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .frame(width: 20)
                    }
                }

                Text(label)
                    .font(.body)
                    .foregroundStyle(isOn ? .primary : .secondary)

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isOn ? color : Color.appBorder)
                    .animation(.easeOut(duration: 0.15), value: isOn)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(isOn ? color.opacity(0.07) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
