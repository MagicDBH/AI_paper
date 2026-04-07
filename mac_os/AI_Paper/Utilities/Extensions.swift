import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh-CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }

    var displayString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: self))"
        } else {
            return shortFormatted
        }
    }
}

// MARK: - String Extensions
extension String {
    var wordCount: Int { count }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isNotEmpty: Bool { !isEmpty }

    func truncated(to maxLength: Int, trailing: String = "...") -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + trailing
    }

    func splitByParagraphs() -> [String] {
        components(separatedBy: "\n\n").filter { !$0.trimmed.isEmpty }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// MARK: - Color Extensions
extension Color {
    static let aiPaperBackground = Color(NSColor.windowBackgroundColor)
    static let aiPaperCard = Color(NSColor.controlBackgroundColor)
    static let aiPaperBorder = Color(NSColor.separatorColor)

    static let riskHigh = Color.red
    static let riskMedium = Color.orange
    static let riskLow = Color.green
}

// MARK: - NSColor Helper
extension NSColor {
    static func adaptive(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
