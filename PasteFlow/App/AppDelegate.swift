import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    private var historyTrimTimer: Timer?
    let appEnvironment = AppEnvironment()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Как в Clipy: скрыть из Cmd+Tab и Dock — только статус-бар
        NSApp.setActivationPolicy(.accessory)
        
        menuBarController = MenuBarController(appEnvironment: appEnvironment)
        
        ClipboardMonitor.shared.startMonitoring()
        
        ShortcutManager.shared.onTriggerMainHotkey = { [weak self] in
            self?.menuBarController?.showPopover(nil, tab: 0)
        }
        ShortcutManager.shared.onTriggerHistoryHotkey = { [weak self] in
            self?.menuBarController?.openPreferences()
        }
        ShortcutManager.shared.onTriggerSnippetsHotkey = { [weak self] in
            self?.menuBarController?.showPopover(nil, tab: 1)
        }
        ShortcutManager.shared.onTriggerTextAssistantHotkey = { [weak self] in
            self?.menuBarController?.openTextAssistant()
        }
        
        ShortcutManager.shared.startMonitoring()
        
        // Clipy: периодически обрезать историю до лимита (каждые 60 секунд)
        historyTrimTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            ClipboardHistoryManager.shared.enforceLimit()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        historyTrimTimer?.invalidate()
    }
}
