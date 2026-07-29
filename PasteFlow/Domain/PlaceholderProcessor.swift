import Foundation
import Cocoa

class PlaceholderProcessor {
    static let shared = PlaceholderProcessor()
    
    struct PlaceholderItem {
        let tag: String
        let description: String
    }
    
    static let availablePlaceholders: [PlaceholderItem] = [
        PlaceholderItem(tag: "{CLIPBOARD}", description: "Current clipboard text"),
        PlaceholderItem(tag: "{DATE}", description: "Current date (e.g. 2026-07-24)"),
        PlaceholderItem(tag: "{TIME}", description: "Current time (e.g. 14:30)"),
        PlaceholderItem(tag: "{YEAR}", description: "Current year (e.g. 2026)"),
        PlaceholderItem(tag: "{MONTH}", description: "Current month (e.g. 07)"),
        PlaceholderItem(tag: "{DAY}", description: "Current day (e.g. 24)"),
        PlaceholderItem(tag: "{WEEKDAY}", description: "Day of the week"),
        PlaceholderItem(tag: "{HOUR}", description: "Current hour (e.g. 14)"),
        PlaceholderItem(tag: "{MINUTE}", description: "Current minute (e.g. 30)"),
        PlaceholderItem(tag: "{SECOND}", description: "Current second (e.g. 05)"),
        PlaceholderItem(tag: "{UUID}", description: "Random UUID"),
        PlaceholderItem(tag: "{HOSTNAME}", description: "Computer name"),
        PlaceholderItem(tag: "{USERNAME}", description: "Account username"),
        PlaceholderItem(tag: "{FULLNAME}", description: "Account full name")
    ]
    
    func process(_ content: String) -> String {
        var result = content
        let now = Date()
        let calendar = Calendar.current
        
        let year = String(calendar.component(.year, from: now))
        let month = String(format: "%02d", calendar.component(.month, from: now))
        let day = String(format: "%02d", calendar.component(.day, from: now))
        let hour = String(format: "%02d", calendar.component(.hour, from: now))
        let minute = String(format: "%02d", calendar.component(.minute, from: now))
        let second = String(format: "%02d", calendar.component(.second, from: now))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateStr = dateFormatter.string(from: now)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let timeStr = timeFormatter.string(from: now)
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == "ru" ? "ru_RU" : "en_US")
        weekdayFormatter.dateFormat = "EEEE"
        let weekdayStr = weekdayFormatter.string(from: now)
        
        let clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
        let uuidStr = UUID().uuidString
        let hostname = Host.current().localizedName ?? "Mac"
        let username = NSUserName()
        let fullname = NSFullUserName()
        
        let replacements: [(String, String)] = [
            ("{CLIPBOARD}", clipboardText),
            ("{clipboard}", clipboardText),
            ("{DATE}", dateStr),
            ("{date}", dateStr),
            ("{TIME}", timeStr),
            ("{time}", timeStr),
            ("{YEAR}", year),
            ("{year}", year),
            ("{MONTH}", month),
            ("{month}", month),
            ("{DAY}", day),
            ("{day}", day),
            ("{WEEKDAY}", weekdayStr),
            ("{weekday}", weekdayStr),
            ("{HOUR}", hour),
            ("{hour}", hour),
            ("{MINUTE}", minute),
            ("{minute}", minute),
            ("{SECOND}", second),
            ("{second}", second),
            ("{UUID}", uuidStr),
            ("{uuid}", uuidStr),
            ("{HOSTNAME}", hostname),
            ("{hostname}", hostname),
            ("{USERNAME}", username),
            ("{username}", username),
            ("{FULLNAME}", fullname),
            ("{fullname}", fullname),
            ("{CURSOR}", ""),
            ("{cursor}", "")
        ]
        
        for (tag, value) in replacements {
            result = result.replacingOccurrences(of: tag, with: value)
        }
        
        return result
    }
}
