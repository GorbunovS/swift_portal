import SwiftUI

// Класс для управления темой приложения
class Theme {
    // Цвета из theme.css
    struct LightTheme {
        static let backgroundColor = Color(hex: "#F1F4F7")
        static let secondaryBackgroundColor = Color(hex: "#ffffff")
        static let buttonsBackgroundColor = Color(hex: "#011c36")
        static let cardsBackgroundColor = Color(hex: "#ffffff")
        static let hoverColor = Color(hex: "#e5e5e6")
        static let textColor = Color(hex: "#333333")
        static let secondTextColor = Color(hex: "#7D8D9C")
        static let secondaryTextColor = Color(hex: "#052a55")
        static let primaryColor = Color(hex: "#d6e8f8")
        static let secondaryColor = Color(hex: "#e0e4e9")
        static let headerBg = Color(hex: "#011c36")
    }
    
    struct DarkTheme {
        static let backgroundColor = Color(hex: "#081018")
        static let secondaryBackgroundColor = Color(hex: "#121c24")
        static let buttonsBackgroundColor = Color(hex: "#03519C")
        static let cardsBackgroundColor = Color(hex: "#1b2a36")
        static let hoverColor = Color(hex: "#081018")
        static let textColor = Color(hex: "#ffffff")
        static let secondTextColor = Color(hex: "#7D8D9C")
        static let systemTextColor = Color(hex: "#ffffff")
        static let secondaryTextColor = Color(hex: "#85b9f1")
        static let primaryColor = Color(hex: "#011c36")
        static let secondaryColor = Color(hex: "#373737")
        static let headerBg = Color(hex: "#011C36")
    }
}

// Расширение для создания цвета из HEX
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Структура для определения шрифтов приложения
struct FontTheme {
    static let title = Font.custom("Racama-U", size: 24)
    static let header = Font.custom("Racama-U", size: 20)
    static let body = Font.custom("Racama-U", size: 16)
    static let caption = Font.custom("Racama-U", size: 14)
    static let small = Font.custom("Racama-U", size: 12)
} 
