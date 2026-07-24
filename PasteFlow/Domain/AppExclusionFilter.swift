import Cocoa

class AppExclusionFilter: ObservableObject {
    static let shared = AppExclusionFilter()
    
    private let storageKey = "PasteFlow.ExcludedBundleIDs"
    
    @Published var excludedBundleIDs: Set<String> = [] {
        didSet {
            save()
        }
    }
    
    init() {
        load()
    }
    
    private func load() {
        if let array = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            excludedBundleIDs = Set(array)
        } else {
            excludedBundleIDs = [
                "com.1password.1password",
                "com.apple.keychainaccess",
                "com.bitwarden.desktop",
                "com.lastpass.lastpass",
                "com.dashlane.Dashlane"
            ]
        }
    }
    
    private func save() {
        UserDefaults.standard.set(Array(excludedBundleIDs), forKey: storageKey)
    }
    
    func addExclusion(_ bundleID: String) {
        excludedBundleIDs.insert(bundleID)
    }
    
    func removeExclusion(_ bundleID: String) {
        excludedBundleIDs.remove(bundleID)
    }
    
    func isCurrentAppExcluded() -> Bool {
        var targetApp = NSWorkspace.shared.frontmostApplication
        
        // Если активное приложение — сам PasteFlow (например, открыт попап),
        // проверяем приложение, из которого совершался переход (источник копирования)
        if targetApp?.bundleIdentifier == Bundle.main.bundleIdentifier {
            if let delegate = NSApp.delegate as? AppDelegate {
                targetApp = delegate.menuBarController?.previousApplication
            }
        }
        
        guard let bundleID = targetApp?.bundleIdentifier else {
            return false
        }
        
        // Сравниваем регистронезависимо для надежности
        return excludedBundleIDs.contains { $0.localizedCaseInsensitiveCompare(bundleID) == .orderedSame }
    }
}
