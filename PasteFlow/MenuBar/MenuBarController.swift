import Cocoa
import SwiftUI

class MenuBarController: ObservableObject {
    @Published var selectedTab: Int = 0
    
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?
    private var workspaceObserver: Any?
    
    /// Приложение, активное ДО открытия попапа.
    /// Обновляется через NSWorkspace уведомления — более надёжно, чем одноразовый снимок.
    private(set) var previousApplication: NSRunningApplication?
    
    private var preferencesWindow: NSWindow?
    private var snippetManagerWindow: NSWindow?

    init() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 470)
        // .semitransient: закрывается при клике вне, но не требует NSApp.activate()
        popover.behavior = .semitransient
        popover.animates = true

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PasteFlow")
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
            // Не перезаписывать, если активировался PasteFlow
            if app?.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.previousApplication = app
            }
        }
        // Инициализируем текущим фронтальным приложением
        previousApplication = NSWorkspace.shared.frontmostApplication
    }

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
        
        if let button = statusItem.button {
            // Запоминаем активное приложение до того, как PasteFlow получит фокус
            let currentApp = NSWorkspace.shared.frontmostApplication
            if currentApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousApplication = currentApp
            }
            
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApp.activate(ignoringOtherApps: true)
            
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let strongSelf = self, strongSelf.popover.isShown {
                    strongSelf.closePopover(event)
                }
            }
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        // Не сбрасывать previousApplication здесь — PasteEngine может обратиться к нему после закрытия
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
        window.title = "Настройки PasteFlow"
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
        window.title = "Менеджер сниппетов"
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
}
