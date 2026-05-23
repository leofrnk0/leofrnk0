import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showAdminLogin  = false
    @State private var showChangePIN   = false
    @State private var newPIN          = ""
    @State private var confirmPIN      = ""
    @State private var pinMismatch     = false
    @State private var showPrivacy     = false
    @State private var showGuidelines  = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sportSection
                    Divider().background(Color.appBorder)
                    adminSection
                    Divider().background(Color.appBorder)
                    legalSection
                    Divider().background(Color.appBorder)
                    aboutSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAdminLogin) { AdminLoginView() }
        .sheet(isPresented: $showPrivacy)    { PrivacySheet() }
        .sheet(isPresented: $showGuidelines) { GuidelinesSheet() }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 520)
        #endif
    }

    // MARK: - Sport section

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("My Sports", systemImage: "figure.run")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Only enabled sports are shown in the library.")
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
                        Text("Admin Active")
                            .font(.callout.weight(.medium))
                        Spacer()
                        Button("Log Out") { settings.logout() }
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
                            Label("Change PIN", systemImage: "key.fill")
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
                        Text("Log in as Admin")
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

    // MARK: - Legal section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Legal", systemImage: "doc.text.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                legalRow(icon: "hand.raised.fill", color: Color.mutedBlue,
                         title: "Privacy Policy",
                         subtitle: "How your data is handled") { showPrivacy = true }
                Divider().background(Color.appBorder).padding(.leading, 44)
                legalRow(icon: "list.bullet.clipboard.fill", color: Color.mutedGreen,
                         title: "Usage Guidelines",
                         subtitle: "Rules and best practices") { showGuidelines = true }
            }
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
        }
    }

    private func legalRow(icon: String, color: Color, title: String,
                          subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon).font(.callout).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.callout.weight(.medium)).foregroundStyle(.primary)
                    Text(subtitle).font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("About", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.mutedCyan.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: "figure.pool.swim")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.mutedCyan)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("TriWorkouts").font(.headline).foregroundStyle(.primary)
                    Text("Personal training library for triathletes")
                        .font(.caption).foregroundStyle(.tertiary)
                    Text("Version 1.0  ·  Leo Franken")
                        .font(.caption2.monospacedDigit()).foregroundStyle(Color(white: 0.4))
                }
                Spacer()
            }
            .padding(14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
        }
    }

    private var changePINFields: some View {
        VStack(spacing: 8) {
            SecureField("New PIN", text: $newPIN)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder))
            SecureField("Confirm PIN", text: $confirmPIN)
                .padding(12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                    pinMismatch ? Color.mutedRed.opacity(0.6) : Color.appBorder))
            if pinMismatch {
                Text("PINs do not match")
                    .font(.caption)
                    .foregroundStyle(Color.mutedRed)
            }
            HStack(spacing: 8) {
                Button("Cancel") {
                    newPIN = ""; confirmPIN = ""; pinMismatch = false; showChangePIN = false
                }
                .font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 10))
                .buttonStyle(.plain)

                Button("Save") {
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

// MARK: - Privacy sheet

private struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    policyBlock(icon: "internaldrive.fill", color: Color.mutedBlue, title: "Local Storage Only") {
                        "All your workouts and settings are stored exclusively on this device. No data is uploaded to any server, cloud service, or third party."
                    }
                    policyBlock(icon: "eye.slash.fill", color: Color.mutedGreen, title: "No Tracking") {
                        "TriWorkouts does not collect analytics, usage data, crash reports, or any other telemetry. The app has no internet connection and makes no network requests."
                    }
                    policyBlock(icon: "person.slash.fill", color: Color.mutedOrange, title: "No Personal Data") {
                        "The app does not ask for your name, email, location, health data, or any other personal information. Author names you enter for workouts stay on your device."
                    }
                    policyBlock(icon: "trash.fill", color: Color.mutedRed, title: "Deleting Your Data") {
                        "Uninstalling the app permanently removes all stored workouts and settings. There is no account to delete."
                    }
                    policyBlock(icon: "doc.badge.clock.fill", color: Color(white: 0.45), title: "Exported Files") {
                        "When you export a workout (.fit, .zwo, .mrc), the resulting file is saved to your chosen location. TriWorkouts has no control over what you do with exported files."
                    }

                    Text("Last updated: May 2026")
                        .font(.caption2).foregroundStyle(Color(white: 0.35))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 520)
        #endif
    }

    private func policyBlock(icon: String, color: Color, title: String,
                              body: () -> String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon).font(.callout).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.weight(.semibold)).foregroundStyle(.primary)
                Text(body())
                    .font(.callout).foregroundStyle(.secondary).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
    }
}

// MARK: - Guidelines sheet

private struct GuidelinesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    guideBlock(icon: "figure.run", color: Color.mutedGreen, title: "Training Zones") {
                        "Power zones (Z1–Z5) are based on a percentage of your FTP (Functional Threshold Power). Update your FTP regularly — roughly every 6–8 weeks or after a significant fitness change — to keep TSS and IF values accurate."
                    }
                    guideBlock(icon: "waveform.path.ecg", color: Color.mutedOrange, title: "TSS & IF") {
                        "Intensity Factor (IF) is the ratio of workout intensity to threshold. Training Stress Score (TSS) measures cumulative load. An IF above 1.05 is unsustainable for long durations. Keep weekly TSS increases below 10% to avoid overtraining."
                    }
                    guideBlock(icon: "figure.pool.swim", color: Color.mutedCyan, title: "Swimming — CSS") {
                        "Critical Swim Speed (CSS) is the swimming equivalent of FTP. It is estimated from a 400 m and 200 m time trial. Threshold intervals should be swum at or just below CSS pace."
                    }
                    guideBlock(icon: "bicycle", color: Color.mutedOrange, title: "Cycling — Sweet Spot") {
                        "Sweet Spot training (88–93% FTP, upper Z3 / lower Z4) delivers strong training stimulus with faster recovery than full threshold work. Ideal for building aerobic base."
                    }
                    guideBlock(icon: "bolt.fill", color: Color.mutedRed, title: "VO2max Intervals") {
                        "VO2max intervals (Z5, >105% FTP) should be short (3–8 min) with equal or longer recovery. Limit VO2max sessions to 1–2 per week and avoid them when fatigued."
                    }
                    guideBlock(icon: "moon.zzz.fill", color: Color(white: 0.45), title: "Recovery") {
                        "Never skip recovery days. Z1 rides, easy swims, and rest allow adaptation. Symptoms of overtraining (persistent fatigue, elevated resting HR, poor sleep) should prompt a rest block."
                    }
                    guideBlock(icon: "exclamationmark.triangle.fill", color: Color.mutedYellow, title: "Medical Disclaimer") {
                        "TriWorkouts is a personal training tool, not a substitute for professional coaching or medical advice. Consult a physician before starting a structured training programme, especially if you have pre-existing health conditions."
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Usage Guidelines")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
        #endif
    }

    private func guideBlock(icon: String, color: Color, title: String,
                             body: () -> String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon).font(.callout).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.weight(.semibold)).foregroundStyle(.primary)
                Text(body())
                    .font(.callout).foregroundStyle(.secondary).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder))
    }
}
