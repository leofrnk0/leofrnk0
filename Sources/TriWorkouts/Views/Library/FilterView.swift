import SwiftUI

struct FilterView: View {
    @Environment(WorkoutStore.self) private var store

    var body: some View {
        @Bindable var store = store

        #if os(macOS)
        filterContent
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(Color.appCard)
        #else
        NavigationStack {
            filterContent
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { }
                            .font(.body.weight(.semibold))
                    }
                    if store.activeFilterCount > 0 {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Clear All") { store.clearFilters() }
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
        #endif
    }

    private var filterContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header on macOS
                #if os(macOS)
                HStack {
                    Text("Library")
                        .font(.title2.weight(.bold))
                    Spacer()
                    if store.activeFilterCount > 0 {
                        Button("Clear") { store.clearFilters() }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                #endif

                // Sport filter
                FilterSection(title: "Sport") {
                    ForEach(Sport.allCases, id: \.self) { sport in
                        FilterRow(
                            label: sport.displayName,
                            icon: sport.icon,
                            color: sport.color,
                            isSelected: store.selectedSports.contains(sport)
                        ) {
                            store.toggleSport(sport)
                        }
                    }
                }

                // Tag filter
                FilterSection(title: "Training Type") {
                    ForEach(WorkoutTag.allCases, id: \.self) { tag in
                        FilterRow(
                            label: tag.displayName,
                            icon: nil,
                            color: tag.color,
                            isSelected: store.selectedTags.contains(tag)
                        ) {
                            store.toggleTag(tag)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }
}

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            VStack(spacing: 0) {
                content
            }
        }
    }
}

private struct FilterRow: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(isSelected ? color : .secondary)
                        .frame(width: 20)
                } else {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .frame(width: 20)
                }
                Text(label)
                    .font(.body)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? color.opacity(0.08) : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
