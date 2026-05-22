import SwiftUI

// MARK: - App-wide semantic colors

extension Color {
    static let appBackground = Color(red: 0.039, green: 0.043, blue: 0.063)
    static let appCard       = Color(red: 0.067, green: 0.075, blue: 0.102)
    static let appElevated   = Color(red: 0.102, green: 0.114, blue: 0.149)
    static let appBorder     = Color(red: 0.161, green: 0.180, blue: 0.235)
}

// MARK: - View modifier for the dark background

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
    }
}
