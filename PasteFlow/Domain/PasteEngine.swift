import Cocoa
import ApplicationServices

class PasteEngine {
    static let shared = PasteEngine()
    
    private var activationObserver: NSObjectProtocol?
    private var fallbackTimer: Timer?
    private var pendingAction: (() -> Void)?
    
    /// Возвращает приложение, в которое нужно вставить текст.
    /// Приоритет: previousApplication из MenuBarController (захваченный ДО открытия попапа).
    /// Именно там был фокус, когда пользователь нажал горячую клавишу.
    private var targetApp: NSRunningApplication? {
        if let delegate = NSApp.delegate as? AppDelegate,
           let app = delegate.menuBarController?.previousApplication {
            return app
        }
        return NSWorkspace.shared.frontmostApplication
    }
    
    /// Вставляет элемент истории буфера обмена в приложение, которое было активно до открытия попапа.
    func paste(entry: CDClipboardEntry, asPlainText: Bool = false) {
        let target = targetApp
        
        // Закрыть попап через MenuBarController
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.menuBarController?.closePopover(nil)
        }
        
        executeWhenAppActivated(targetApp: target) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            if asPlainText || entry.contentType == "plainText" {
                if let string = entry.rawString ?? entry.plainTextPreview {
                    pasteboard.setString(string, forType: .string)
                }
            } else {
                switch entry.contentType {
                case "image":
                    if let data = entry.rawContent, let image = NSImage(data: data) {
                        pasteboard.writeObjects([image])
                    }
                case "rtf":
                    if let rtf = entry.rtfData {
                        pasteboard.setData(rtf, forType: .rtf)
                    }
                    if let text = entry.rawString {
                        pasteboard.setString(text, forType: .string)
                    }
                case "pdf":
                    if let pdf = entry.pdfData {
                        pasteboard.setData(pdf, forType: .pdf)
                    }
                case "file":
                    let urls = entry.fileURLs
                    if !urls.isEmpty {
                        let paths = urls.map { $0.path }
                        pasteboard.writeObjects(urls as [NSURL])
                        pasteboard.setPropertyList(paths, forType: NSPasteboard.PasteboardType("NSFilenamesPboardType"))
                        pasteboard.setString(paths.joined(separator: "\n"), forType: .string)
                    }
                default:
                    if let string = entry.rawString {
                        pasteboard.setString(string, forType: .string)
                    }
                }
            }
            
            if UserDefaults.standard.bool(forKey: "PasteFlow.PlaySoundOnPaste") {
                NSSound.beep()
            }
            
            self.simulatePaste()
        }
    }
    
    /// Вставляет произвольный текст (сниппет или результат проверки) в указанное или ранее активное приложение.
    func paste(text: String, targetApp specifiedTarget: NSRunningApplication? = nil) {
        let target = specifiedTarget ?? targetApp
        
        // Закрыть попап через MenuBarController
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.menuBarController?.closePopover(nil)
        }
        
        executeWhenAppActivated(targetApp: target) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            if UserDefaults.standard.bool(forKey: "PasteFlow.PlaySoundOnPaste") {
                NSSound.beep()
            }
            
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        // Подавить локальные клавиатурные события во время вставки (как в Clipy)
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )
        
        let vKeyCode: CGKeyCode = 0x09 // V (QWERTY)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // cgAnnotatedSessionEventTap надёжнее для вставки в другие приложения
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    // MARK: - Adaptive Activation Logic
    
    private func executeWhenAppActivated(targetApp: NSRunningApplication?, action: @escaping () -> Void) {
        cleanupPendingPaste()
        
        guard let target = targetApp else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
            return
        }
        
        if NSWorkspace.shared.frontmostApplication == target {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                action()
            }
            return
        }
        
        self.pendingAction = action
        
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            
            if app == target {
                self.performPendingPaste()
            }
        }
        
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            self?.performPendingPaste()
        }
        
        target.activate(options: .activateIgnoringOtherApps)
    }
    
    private func performPendingPaste() {
        guard let action = pendingAction else { return }
        cleanupPendingPaste()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            action()
        }
    }
    
    private func cleanupPendingPaste() {
        if let observer = activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            activationObserver = nil
        }
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        pendingAction = nil
    }
}
