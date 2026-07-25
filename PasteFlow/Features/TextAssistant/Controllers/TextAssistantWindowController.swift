import Cocoa
import SwiftUI

class TextAssistantPanel: NSPanel {
    var onEscapePressed: (() -> Void)?
    var onCmdEnterPressed: (() -> Void)?
    
    override func cancelOperation(_ sender: Any?) {
        onEscapePressed?()
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // Cmd + Enter (keyCode 36 = Return)
            if flags == .command && event.keyCode == 36 {
                onCmdEnterPressed?()
                return true
            }
            // Esc (keyCode 53)
            if event.keyCode == 53 {
                onEscapePressed?()
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

class TextAssistantWindowController: NSWindowController {
    static let shared = TextAssistantWindowController()
    
    private var panel: TextAssistantPanel?
    private var onCopyAction: (() -> Void)?
    
    convenience init() {
        let window = TextAssistantPanel(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.center()
        window.title = "Text Assistant"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PasteFlowTextAssistantWindow")
        
        self.init(window: window)
        self.panel = window
        
        window.onEscapePressed = { [weak self] in
            self?.closeWindow()
        }
        window.onCmdEnterPressed = { [weak self] in
            self?.onCopyAction?()
        }
    }
    
    func showWindow() {
        if panel == nil {
            let window = TextAssistantPanel(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 480),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.level = .floating
            window.center()
            window.title = "Text Assistant"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("PasteFlowTextAssistantWindow")
            
            window.onEscapePressed = { [weak self] in
                self?.closeWindow()
            }
            window.onCmdEnterPressed = { [weak self] in
                self?.onCopyAction?()
            }
            
            self.window = window
            self.panel = window
        }
        
        let rootView = TextAssistantWindowView(
            onClose: { [weak self] in
                self?.closeWindow()
            },
            onRegisterCopyHandler: { [weak self] copyHandler in
                self?.onCopyAction = copyHandler
            }
        )
        
        panel?.contentView = NSHostingView(rootView: rootView)
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeWindow() {
        let shouldClear = UserDefaults.standard.bool(forKey: "PasteFlow.ClearTextAssistantOnClose")
        if shouldClear {
            UserDefaults.standard.set("", forKey: "PasteFlow.LastAssistantInputText")
        }
        panel?.orderOut(nil)
    }
}
