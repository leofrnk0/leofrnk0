import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showAdminLogin  = false
    @State private var showChangePIN   = false
    @State private var newPIN          = ""
    @State private var confirmPIN      = ""
    @State private var pinMismatch     = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sportSection
                    Divider().background(Color.appBorder)
                    adminSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Einstellungen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAdminLogin) { AdminLoginView() }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 420)
        #else
        .presentationDetents([.medium, .large])
        #endif
    }

    // MARK: - Sport section

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Meine Sportarten", systemImage: "figure.run")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Nur aktivierte Sportarten werden in der Bibliothek angezeigt.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 10) {
                ForEach(Sport.allCases, id: \.self) { sport in
                    let on = settings.enabledSports.contains(sport)
                    Button { settings.toggleSport(sport) } label: {
                        VStack(spacing: 6) {
                            Image(systemName: sport.icon)
                                .font(.title2.weight(.semibold))
                            Text(sport.displayName)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(on ? .white : sport.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(on ? sport.color : sport.color.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(on ? sport.color : sport.color.opacity(0.30), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeOut(duration: 0.15), value: on)
                }
            }
        }
    }

    // MARK: - Admin section

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Admin", systemImage: settings.isAdmin ? "lock.open.fill" : "lock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if settings.isAdmin {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color.mutedGreen)
                        Text("Admin aktiv")
                            .font(.callout.weight(.medium))
                        Spacer()
                        Button("Abmelden") { settings.logout() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.mutedRed)
                    }
                    .padding(14)
                    .background(Color.mutedGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mutedGreen.opacity(0.25)))

                    if showChangePIN {
                        changePINFields
                    } else {
                        Button { showChangePIN = true } label: {
                            Label("PIN ändern", systemImage: "key.fill")
                                .font(.callout.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button { showAdminLogin = true } label: {
                    HStack {
                        Image(systemName: "lock.fill").foregroundStyle(Color.mutedOrange)
                        Text("Als Admin anmelden")
                            .font(.callout.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var changePINFields: some View {
        VStack(spacing: 8) {
            SecureField("Neuer PIN", text: $newPIN)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
            SecureField("PIN bestätigen", text: $confirmPIN)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                    pinMismatch ? Color.mutedRed.opacity(0.6) : Color.appBorder))
            if pinMismatch {
                Text("PINs stimmen nicht überein")
                    .font(.caption)
                    .foregroundStyle(Color.mutedRed)
            }
            HStack(spacing: 8) {
                Button("Abbrechen") {
                    newPIN = ""; confirmPIN = ""; pinMismatch = false; showChangePIN = false
                }
                .font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .buttonStyle(.plain)

                Button("Speichern") {
                    guard newPIN.count >= 4 else { pinMismatch = true; return }
                    guard newPIN == confirmPIN else { pinMismatch = true; return }
                    settings.changePin(to: newPIN)
                    newPIN = ""; confirmPIN = ""; pinMismatch = false; showChangePIN = false
                }
                .font(.callout.weight(.semibold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.mutedGreen, in: RoundedRectangle(cornerRadius: 10))
                .buttonStyle(.plain)
            }
        }
    }
}
