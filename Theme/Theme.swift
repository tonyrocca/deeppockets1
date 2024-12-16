import SwiftUI

enum Theme {
    // MARK: - Custom Colors
    static let darkBackground = Color(hex: "121212")  // Very dark gray, almost black
    static let surfaceBackground = Color(hex: "1E1E1E")  // Dark gray for cards
    static let elevatedBackground = Color(hex: "242424")  // Slightly lighter gray for elevated surfaces
    static let accentGreen = Color(hex: "00875A")  // Dark green accent
    static let mutedGreen = Color(hex: "004D40")  // Darker muted green
    static let separator = Color(hex: "2A2A2A")  // Subtle separator color
    
    // MARK: - Semantic Colors
    static let background = darkBackground
    static let secondaryBackground = surfaceBackground
    static let tertiaryBackground = elevatedBackground
    static let label = Color.white
    static let secondaryLabel = Color.white.opacity(0.7)
    static let tint = accentGreen
    
    // MARK: - Font Sizes
    static let largeTitle = Font.largeTitle.bold()
    static let title = Font.title.bold()
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    
    // MARK: - Button Style
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accentGreen)
                .cornerRadius(10)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    // MARK: - Text Field Style
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(elevatedBackground)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
