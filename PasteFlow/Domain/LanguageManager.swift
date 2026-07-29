import SwiftUI
import Foundation

enum Language: String, CaseIterable, Identifiable {
    case en = "English"
    case ru = "Русский"
    
    var id: String { rawValue }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("PasteFlow.Language") var currentLanguage: String = "en" {
        didSet {
            updateBundle()
        }
    }
    
    private var bundle: Bundle?
    
    private init() {
        updateBundle()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            self.bundle = languageBundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    func tr(_ key: String) -> String {
        guard let bundle = bundle else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.tr(self)
    }
}
