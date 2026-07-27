import Cocoa
import SwiftUI

class MenuBarController: NSObject, ObservableObject, NSPopoverDelegate {
    @Published var selectedTab: Int = 0
    
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?
    private var workspaceObserver: Any?
    
    /// Приложение, активное ДО открытия попапа.
    private(set) var previousApplication: NSRunningApplication?
    
    private var preferencesWindow: NSWindow?
    private var snippetManagerWindow: NSWindow?

    override init() {
        popover = NSPopover()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        
        popover.delegate = self
        popover.contentSize = NSSize(width: 350, height: 470)
        popover.behavior = .semitransient
        popover.animates = true

        if let button = statusItem.button {
            let symbolImage = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PasteFlow")
                           ?? NSImage(systemSymbolName: "clipboard", accessibilityDescription: "PasteFlow")
                           ?? NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "PasteFlow")
            if let img = symbolImage {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                button.image = img
            } else {
                button.title = "📋"
            }
            button.imagePosition = .imageOnly
            button.toolTip = "PasteFlow"
            button.action = #selector(togglePopoverAction(_:))
            button.target = self
        }
        
        let contentView = PopupRootView(controller: self)
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        
        // Слушаем смену активного приложения через NSWorkspace
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            if app?.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.previousApplication = app
            }
        }
        previousApplication = NSWorkspace.shared.frontmostApplication
    }

    private var inactivityTimer: Timer?
    private var localEventMonitor: Any?

    @objc func togglePopoverAction(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?, tab: Int? = nil) {
        if let tab = tab {
            self.selectedTab = tab
        }
        
        if popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        if let button = statusItem.button {
            let currentApp = NSWorkspace.shared.frontmostApplication
            if currentApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousApplication = currentApp
            }
            
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApp.activate(ignoringOtherApps: true)
            
            if eventMonitor != nil {
                NSEvent.removeMonitor(eventMonitor!)
                eventMonitor = nil
            }
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let strongSelf = self, strongSelf.popover.isShown {
                    strongSelf.closePopover(event)
                }
            }
            
            if localEventMonitor != nil {
                NSEvent.removeMonitor(localEventMonitor!)
                localEventMonitor = nil
            }
            localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel]) { [weak self] event in
                self?.resetInactivityTimer()
                return event
            }
            resetInactivityTimer()
        }
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(nil)
            }
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        // Monitor removal is now handled in popoverDidClose
    }
    
    func popoverDidClose(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        if let localMonitor = localEventMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localEventMonitor = nil
        }
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    func openPreferences() {
        closePopover(nil)
        
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = "menu.title_preferences".localized
        window.setFrameAutosaveName("PasteFlowPreferencesWindow")
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: PreferencesView()
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        )
        self.preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openSnippetManager() {
        closePopover(nil)
        
        if let window = snippetManagerWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 540),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = "menu.title_snippets".localized
        window.setFrameAutosaveName("PasteFlowSnippetManagerWindow")
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: SnippetLibraryView()
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        )
        self.snippetManagerWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openTextAssistant() {
        closePopover(nil)
        TextAssistantWindowController.shared.showWindow()
    }
}
