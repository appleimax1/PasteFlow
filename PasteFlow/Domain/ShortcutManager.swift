import Cocoa
import Carbon

class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var mainHotkeyDisplay: String = "⌥⌘V"
    @Published var historyHotkeyDisplay: String = "⌥⌘H"
    @Published var snippetsHotkeyDisplay: String = "⌥⌘S"
    
    @Published var mainKeyCode: UInt16 = 9
    @Published var mainModifiers: UInt = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    
    @Published var historyKeyCode: UInt16 = 4
    @Published var historyModifiers: UInt = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    
    @Published var snippetsKeyCode: UInt16 = 1
    @Published var snippetsModifiers: UInt = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    
    private var mainHotKeyRef: EventHotKeyRef?
    private var historyHotKeyRef: EventHotKeyRef?
    private var snippetsHotKeyRef: EventHotKeyRef?
    private var eventHandlerRefs: [EventHandlerRef] = [] // Храним ВСЕ обработчики
    
    var onTriggerMainHotkey: (() -> Void)?
    var onTriggerHistoryHotkey: (() -> Void)?
    var onTriggerSnippetsHotkey: (() -> Void)?
    
    init() {
        loadHotkeys()
    }
    
    func loadHotkeys() {
        if let mainCode = UserDefaults.standard.object(forKey: "PasteFlow.MainKeyCode") as? UInt16 {
            mainKeyCode = mainCode
            mainModifiers = UInt(UserDefaults.standard.integer(forKey: "PasteFlow.MainModifiers"))
        }
        if let histCode = UserDefaults.standard.object(forKey: "PasteFlow.HistoryKeyCode") as? UInt16 {
            historyKeyCode = histCode
            historyModifiers = UInt(UserDefaults.standard.integer(forKey: "PasteFlow.HistoryModifiers"))
        }
        if let snipCode = UserDefaults.standard.object(forKey: "PasteFlow.SnippetsKeyCode") as? UInt16 {
            snippetsKeyCode = snipCode
            snippetsModifiers = UInt(UserDefaults.standard.integer(forKey: "PasteFlow.SnippetsModifiers"))
        }
        
        mainHotkeyDisplay = formatDisplay(keyCode: mainKeyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: mainModifiers))
        historyHotkeyDisplay = formatDisplay(keyCode: historyKeyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: historyModifiers))
        snippetsHotkeyDisplay = formatDisplay(keyCode: snippetsKeyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: snippetsModifiers))
    }
    
    func saveMainHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        mainKeyCode = keyCode
        mainModifiers = modifiers.rawValue
        UserDefaults.standard.set(keyCode, forKey: "PasteFlow.MainKeyCode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "PasteFlow.MainModifiers")
        mainHotkeyDisplay = formatDisplay(keyCode: keyCode, modifierFlags: modifiers)
        registerGlobalHotkeys()
    }
    
    func saveHistoryHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        historyKeyCode = keyCode
        historyModifiers = modifiers.rawValue
        UserDefaults.standard.set(keyCode, forKey: "PasteFlow.HistoryKeyCode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "PasteFlow.HistoryModifiers")
        historyHotkeyDisplay = formatDisplay(keyCode: keyCode, modifierFlags: modifiers)
        registerGlobalHotkeys()
    }
    
    func saveSnippetsHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        snippetsKeyCode = keyCode
        snippetsModifiers = modifiers.rawValue
        UserDefaults.standard.set(keyCode, forKey: "PasteFlow.SnippetsKeyCode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "PasteFlow.SnippetsModifiers")
        snippetsHotkeyDisplay = formatDisplay(keyCode: keyCode, modifierFlags: modifiers)
        registerGlobalHotkeys()
    }
    
    func startMonitoring() {
        registerGlobalHotkeys()
    }
    
    func stopMonitoring() {
        unregisterGlobalHotkeys()
    }
    
    private func registerGlobalHotkeys() {
        unregisterGlobalHotkeys()
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        var newHandlerRef: EventHandlerRef?
        InstallEventHandler(GetEventDispatcherTarget(), { (nextHandler, event, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            DispatchQueue.main.async {
                if hotKeyID.id == 1 {
                    ShortcutManager.shared.onTriggerMainHotkey?()
                } else if hotKeyID.id == 2 {
                    ShortcutManager.shared.onTriggerHistoryHotkey?()
                } else if hotKeyID.id == 3 {
                    ShortcutManager.shared.onTriggerSnippetsHotkey?()
                }
            }
            return noErr
        }, 1, &eventType, nil, &newHandlerRef)
        
        if let ref = newHandlerRef {
            eventHandlerRefs.append(ref)
        }
        
        // 1. Main Hotkey (ID 1)
        let mainID = EventHotKeyID(signature: OSType(1111), id: 1)
        RegisterEventHotKey(UInt32(mainKeyCode), carbonModifiers(from: mainModifiers), mainID, GetEventDispatcherTarget(), 0, &mainHotKeyRef)
        
        // 2. History Hotkey (ID 2)
        let historyID = EventHotKeyID(signature: OSType(2222), id: 2)
        RegisterEventHotKey(UInt32(historyKeyCode), carbonModifiers(from: historyModifiers), historyID, GetEventDispatcherTarget(), 0, &historyHotKeyRef)
        
        // 3. Snippets Hotkey (ID 3)
        let snippetsID = EventHotKeyID(signature: OSType(3333), id: 3)
        RegisterEventHotKey(UInt32(snippetsKeyCode), carbonModifiers(from: snippetsModifiers), snippetsID, GetEventDispatcherTarget(), 0, &snippetsHotKeyRef)
    }
    
    private func unregisterGlobalHotkeys() {
        if let ref = mainHotKeyRef {
            UnregisterEventHotKey(ref)
            mainHotKeyRef = nil
        }
        if let ref = historyHotKeyRef {
            UnregisterEventHotKey(ref)
            historyHotKeyRef = nil
        }
        if let ref = snippetsHotKeyRef {
            UnregisterEventHotKey(ref)
            snippetsHotKeyRef = nil
        }
        // Снять ВСЕ EventHandler-ы, предотвращая утечки
        eventHandlerRefs.forEach { RemoveEventHandler($0) }
        eventHandlerRefs.removeAll()
    }
    
    private func carbonModifiers(from nsRawModifiers: UInt) -> UInt32 {
        var carbonFlags: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: nsRawModifiers)
        if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        return carbonFlags
    }
    
    func formatDisplay(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> String {
        var str = ""
        if modifierFlags.contains(.control) { str += "⌃" }
        if modifierFlags.contains(.option) { str += "⌥" }
        if modifierFlags.contains(.shift) { str += "⇧" }
        if modifierFlags.contains(.command) { str += "⌘" }
        
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 36: "Return"
        ]
        
        str += keyMap[keyCode] ?? "Key \(keyCode)"
        return str
    }
}
