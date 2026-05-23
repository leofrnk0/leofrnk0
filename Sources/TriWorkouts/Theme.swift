import SwiftUI

// MARK: - App-wide semantic colors

extension Color {
    static let appBackground = Color(red: 0.039, green: 0.043, blue: 0.063)
    static let appCard       = Color(red: 0.067, green: 0.075, blue: 0.102)
    static let appElevated   = Color(red: 0.102, green: 0.114, blue: 0.149)
    static let appBorder     = Color(red: 0.161, green: 0.180, blue: 0.235)

    // Accent palette – desaturated enough to avoid neon, bright enough to glow on dark backgrounds
    static let mutedOrange = Color(red: 0.86, green: 0.52, blue: 0.28)
    static let mutedGreen  = Color(red: 0.26, green: 0.74, blue: 0.44)
    static let mutedCyan   = Color(red: 0.20, green: 0.70, blue: 0.78)
    static let mutedBlue   = Color(red: 0.32, green: 0.54, blue: 0.84)
    static let mutedRed    = Color(red: 0.80, green: 0.30, blue: 0.30)
    static let mutedYellow = Color(red: 0.82, green: 0.70, blue: 0.26)
    static let mutedPurple = Color(red: 0.60, green: 0.36, blue: 0.76)
}

// MARK: - View modifier for the dark background

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
    }
}
