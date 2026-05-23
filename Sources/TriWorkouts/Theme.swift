import SwiftUI

// MARK: - App-wide semantic colors

extension Color {
    static let appBackground = Color(red: 0.039, green: 0.043, blue: 0.063)
    static let appCard       = Color(red: 0.067, green: 0.075, blue: 0.102)
    static let appElevated   = Color(red: 0.102, green: 0.114, blue: 0.149)
    static let appBorder     = Color(red: 0.161, green: 0.180, blue: 0.235)

    // Muted accent palette – desaturated versions of standard hues
    static let mutedOrange = Color(red: 0.68, green: 0.42, blue: 0.24)
    static let mutedGreen  = Color(red: 0.22, green: 0.56, blue: 0.34)
    static let mutedCyan   = Color(red: 0.18, green: 0.52, blue: 0.58)
    static let mutedBlue   = Color(red: 0.24, green: 0.44, blue: 0.65)
    static let mutedRed    = Color(red: 0.62, green: 0.24, blue: 0.24)
    static let mutedYellow = Color(red: 0.62, green: 0.54, blue: 0.20)
    static let mutedPurple = Color(red: 0.46, green: 0.28, blue: 0.58)
}

// MARK: - View modifier for the dark background

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
    }
}
