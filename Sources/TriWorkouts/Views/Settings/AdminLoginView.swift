import SwiftUI

struct AdminLoginView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var failed = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: failed ? "lock.slash.fill" : "lock.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(failed ? Color.mutedRed : Color.mutedOrange)
                    .animation(.easeOut(duration: 0.2), value: failed)

                VStack(spacing: 6) {
                    Text("Admin-Login")
                        .font(.title2.weight(.bold))
                    Text(failed ? "Falscher PIN – nochmal versuchen" : "PIN eingeben")
                        .font(.callout)
                        .foregroundStyle(failed ? Color.mutedRed : .secondary)
                        .animation(.easeOut(duration: 0.2), value: failed)
                }

                SecureField("PIN", text: $pin)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .padding(.vertical, 16)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(failed ? Color.mutedRed.opacity(0.6) : Color.appBorder, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 40)

                Button {
                    if settings.login(pin: pin) {
                        dismiss()
                    } else {
                        failed = true
                        pin = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { failed = false }
                    }
                } label: {
                    Text("Anmelden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pin.isEmpty ? Color.appElevated : Color.mutedOrange,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(pin.isEmpty ? Color.secondary : .white)
                }
                .buttonStyle(.plain)
                .disabled(pin.isEmpty)
                .padding(.horizontal, 40)
                .animation(.easeOut(duration: 0.15), value: pin.isEmpty)

                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .onAppear { focused = true }
        #if os(macOS)
        .frame(width: 320, height: 380)
        #else
        .presentationDetents([.medium])
        #endif
    }
}
