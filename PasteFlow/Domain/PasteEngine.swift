import Cocoa
import ApplicationServices

class PasteEngine {
    static let shared = PasteEngine()
    
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
        
        // Активировать целевое приложение
        target?.activate(options: .activateIgnoringOtherApps)
        
        // Дать системе время вернуть фокус (150 мс), затем записать данные и нажать Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
                        pasteboard.writeObjects(urls as [NSURL])
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
        
        target?.activate(options: .activateIgnoringOtherApps)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
}
