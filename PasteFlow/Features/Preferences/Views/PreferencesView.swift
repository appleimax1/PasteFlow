import SwiftUI
import ServiceManagement

enum PreferenceTab: String, CaseIterable, Identifiable {
    case general
    case menu
    case types
    case exclusions
    case hotkeys
    case textAssistant
    case backup
    case help
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "tab.general".localized
        case .menu: return "tab.menu".localized
        case .types: return "tab.types".localized
        case .exclusions: return "tab.exclusions".localized
        case .hotkeys: return "tab.hotkeys".localized
        case .textAssistant: return "tab.text_assistant".localized
        case .backup: return "tab.backup".localized
        case .help: return "tab.help".localized
        }
    }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .menu: return "line.3.horizontal.circle.fill"
        case .types: return "doc.on.doc.fill"
        case .exclusions: return "hand.raised.fill"
        case .hotkeys: return "keyboard.fill"
        case .textAssistant: return "checkmark.bubble.fill"
        case .backup: return "arrow.triangle.2.circlepath.circle.fill"
        case .help: return "questionmark.circle.fill"
        }
    }
}

struct PreferencesView: View {
    @State private var selectedTab: PreferenceTab = .general
    @ObservedObject private var langManager = LanguageManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("settings".localized)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ForEach(PreferenceTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == tab ? .white : .accentColor)
                                .frame(width: 20)
                            
                            Text(tab.title)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PasteFlow v1.7")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("app.smart_clipboard_manager".localized)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                    Link("GitHub", destination: URL(string: "https://github.com/appleimax1/PasteFlow")!)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            // Right Detail Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(selectedTab.title)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.bottom, 4)
                    
                    switch selectedTab {
                    case .general:
                        GeneralPrefsTab()
                    case .menu:
                        MenuPrefsTab()
                    case .types:
                        TypesPrefsTab()
                    case .exclusions:
                        ExclusionsPrefsTab()
                    case .hotkeys:
                        HotkeysPrefsTab()
                    case .textAssistant:
                        TextAssistantPrefsTab()
                    case .backup:
                        SnippetsPrefsTab()
                    case .help:
                        HelpPrefsTab()
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Основные Настройки
struct GeneralPrefsTab: View {
    @AppStorage("PasteFlow.MaxHistorySize") private var maxHistorySize = 40
    @AppStorage("PasteFlow.PlaySoundOnPaste") private var playSound = true
    @AppStorage("PasteFlow.LaunchAtLogin") private var launchAtLogin = false
    
    @State private var showClearAlert = false
    @ObservedObject private var langManager = LanguageManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("general.app_behavior".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("general.play_sound".localized, isOn: $playSound)
                        .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle("general.launch_at_login".localized, isOn: $launchAtLogin)
                        .toggleStyle(CheckboxToggleStyle())
                        .onChange(of: launchAtLogin) { newValue in
                            if #available(macOS 13.0, *) {
                                do {
                                    if newValue {
                                        try SMAppService.mainApp.register()
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                    }
                                } catch {
                                    print("Autostart error: \(error)")
                                }
                            }
                        }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            // Language Selection Section
            VStack(alignment: .leading, spacing: 12) {
                Text("general.language".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("general.interface_language".localized)
                            .font(.system(size: 13))
                        
                        Picker("", selection: $langManager.currentLanguage) {
                            Text("English").tag("en")
                            Text("Русский").tag("ru")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("general.history_storage".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("general.max_items".localized)
                            .font(.system(size: 13))
                        
                        Picker("", selection: $maxHistorySize) {
                            Text("general.items_10".localized).tag(10)
                            Text("general.items_20".localized).tag(20)
                            Text("general.items_40".localized).tag(40)
                            Text("general.items_50".localized).tag(50)
                            Text("general.items_100".localized).tag(100)
                            Text("general.items_200".localized).tag(200)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                    
                    Text("general.limit_desc".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("general.data_management".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("general.clear_history_title".localized)
                                .font(.system(size: 12, weight: .semibold))
                            Text("general.clear_history_desc".localized)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("general.clear_history_btn".localized) {
                            showClearAlert = true
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .foregroundColor(.red)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
        }
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("general.clear_history_confirm_title".localized),
                message: Text("general.clear_history_confirm_desc".localized),
                primaryButton: .destructive(Text("general.clear".localized)) {
                    ClipboardHistoryManager.shared.clearHistory()
                },
                secondaryButton: .cancel(Text("general.cancel".localized))
            )
        }
    }
}

// MARK: - Меню и Вид
struct MenuPrefsTab: View {
    @AppStorage("PasteFlow.FolderGroupingSize") private var folderGroupingSize = 10
    @AppStorage("PasteFlow.ShowTooltips") private var showTooltips = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("menu.list_appearance".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("menu.group_subfolders".localized)
                            .font(.system(size: 13))
                        
                        Picker("", selection: $folderGroupingSize) {
                            Text("menu.group_disabled".localized).tag(0)
                            Text("menu.group_10".localized).tag(10)
                            Text("menu.group_20".localized).tag(20)
                            Text("menu.group_30".localized).tag(30)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 220)
                    }
                    
                    Divider()
                    
                    Toggle("menu.show_preview".localized, isOn: $showTooltips)
                        .toggleStyle(CheckboxToggleStyle())
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
        }
    }
}

// MARK: - Типы данных
struct TypesPrefsTab: View {
    @AppStorage("PasteFlow.EnableText") private var enableText = true
    @AppStorage("PasteFlow.EnableImages") private var enableImages = true
    @AppStorage("PasteFlow.EnableRTF") private var enableRTF = true
    @AppStorage("PasteFlow.EnablePDF") private var enablePDF = true
    @AppStorage("PasteFlow.EnableFiles") private var enableFiles = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("types.supported_types".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("types.plain_text".localized, isOn: $enableText)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("types.rich_text".localized, isOn: $enableRTF)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("types.images".localized, isOn: $enableImages)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("types.pdf".localized, isOn: $enablePDF)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("types.files".localized, isOn: $enableFiles)
                        .toggleStyle(CheckboxToggleStyle())
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
        }
    }
}

// MARK: - Исключения
struct ExclusionsPrefsTab: View {
    @ObservedObject private var filter = AppExclusionFilter.shared
    @State private var newBundleID = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("exclusions.blacklist".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("exclusions.desc".localized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            VStack(spacing: 8) {
                List {
                    ForEach(Array(filter.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                        HStack {
                            Image(systemName: "app.dashed")
                                .foregroundColor(.secondary)
                            Text(bundleID)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            Button(action: { filter.removeExclusion(bundleID) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(height: 180)
                .border(Color.secondary.opacity(0.2), width: 1)
                .cornerRadius(6)
                
                HStack {
                    TextField("exclusions.bundle_placeholder".localized, text: $newBundleID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("exclusions.add".localized) {
                        let trimmed = newBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            filter.addExclusion(trimmed)
                            newBundleID = ""
                        }
                    }
                    .disabled(newBundleID.isEmpty)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
        }
    }
}

// MARK: - Горячие клавиши
// MARK: - Горячие клавиши
struct HotkeysPrefsTab: View {
    @ObservedObject private var shortcutMgr = ShortcutManager.shared
    @State private var recordingTarget: Int? = nil // 0: Main/History, 1: Preferences, 2: Snippets, 3: Text Assistant
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("hotkeys.global_shortcuts".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    HotkeyRecorderRow(
                        label: "hotkeys.history_popup".localized,
                        display: shortcutMgr.mainHotkeyDisplay,
                        isRecording: recordingTarget == 0,
                        onStartRecord: { startRecording(target: 0) },
                        onClear: { shortcutMgr.clearMainHotkey() },
                        onReset: { resetHotkey(target: 0) }
                    )
                    
                    Divider()
                    
                    HotkeyRecorderRow(
                        label: "hotkeys.app_settings".localized,
                        display: shortcutMgr.historyHotkeyDisplay,
                        isRecording: recordingTarget == 1,
                        onStartRecord: { startRecording(target: 1) },
                        onClear: { shortcutMgr.clearHistoryHotkey() },
                        onReset: { resetHotkey(target: 1) }
                    )
                    
                    Divider()
                    
                    HotkeyRecorderRow(
                        label: "hotkeys.snippets_popup".localized,
                        display: shortcutMgr.snippetsHotkeyDisplay,
                        isRecording: recordingTarget == 2,
                        onStartRecord: { startRecording(target: 2) },
                        onClear: { shortcutMgr.clearSnippetsHotkey() },
                        onReset: { resetHotkey(target: 2) }
                    )
                    
                    Divider()
                    
                    HotkeyRecorderRow(
                        label: "hotkeys.text_assistant".localized,
                        display: shortcutMgr.textAssistantHotkeyDisplay,
                        isRecording: recordingTarget == 3,
                        onStartRecord: { startRecording(target: 3) },
                        onClear: { shortcutMgr.clearTextAssistantHotkey() },
                        onReset: { resetHotkey(target: 3) }
                    )
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            Text("hotkeys.record_desc".localized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private func startRecording(target: Int) {
        recordingTarget = target
        stopRecordingMonitor()
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            
            if !flags.isEmpty {
                DispatchQueue.main.async {
                    if target == 0 {
                        shortcutMgr.saveMainHotkey(keyCode: keyCode, modifiers: flags)
                    } else if target == 1 {
                        shortcutMgr.saveHistoryHotkey(keyCode: keyCode, modifiers: flags)
                    } else if target == 2 {
                        shortcutMgr.saveSnippetsHotkey(keyCode: keyCode, modifiers: flags)
                    } else if target == 3 {
                        shortcutMgr.saveTextAssistantHotkey(keyCode: keyCode, modifiers: flags)
                    }
                    recordingTarget = nil
                    stopRecordingMonitor()
                }
                return nil
            }
            return event
        }
    }
    
    private func resetHotkey(target: Int) {
        let optCmd = NSEvent.ModifierFlags([.command, .option])
        let shiftCmd = NSEvent.ModifierFlags([.command, .shift])
        if target == 0 {
            shortcutMgr.saveMainHotkey(keyCode: 4, modifiers: shiftCmd) // ⇧⌘H
        } else if target == 1 {
            shortcutMgr.clearHistoryHotkey() // Не назначено
        } else if target == 2 {
            shortcutMgr.saveSnippetsHotkey(keyCode: 1, modifiers: optCmd) // ⌥⌘S
        } else if target == 3 {
            shortcutMgr.saveTextAssistantHotkey(keyCode: 40, modifiers: optCmd) // ⌥⌘K
        }
    }
    
    private func stopRecordingMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

struct HotkeyRecorderRow: View {
    let label: String
    let display: String
    let isRecording: Bool
    let onStartRecord: () -> Void
    let onClear: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onStartRecord) {
                    Text(isRecording ? "hotkeys.press_keys".localized : display)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isRecording ? Color.orange.opacity(0.2) : Color.accentColor.opacity(0.15))
                        )
                        .foregroundColor(isRecording ? .orange : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onClear) {
                    Image(systemName: "multiply")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("hotkeys.clear_tooltip".localized)
                
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("hotkeys.reset_tooltip".localized)
            }
        }
    }
}

// MARK: - Настройки Проверки Текста
struct TextAssistantPrefsTab: View {
    @AppStorage("PasteFlow.ClearTextAssistantOnClose") private var clearOnClose = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("text_assistant.pref_title".localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("text_assistant.pref_behavior_label".localized)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Picker("", selection: $clearOnClose) {
                        Text("text_assistant.pref_option_keep".localized)
                            .tag(false)
                        
                        Text("text_assistant.pref_option_clear".localized)
                            .tag(true)
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .labelsHidden()
                }
                
                Text("text_assistant.pref_desc".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 4)
                
                Text("text_assistant.pref_alt_desc".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
        }
    }
}

// MARK: - Резервное копирование и Импорт
struct SnippetsPrefsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Импорт из XML
            VStack(alignment: .leading, spacing: 12) {
                Text("backup.import_xml".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("backup.import_xml_desc".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                    
                    Button(action: importClipyXML) {
                        Label("backup.import_xml_btn".localized, systemImage: "doc.badge.plus")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            // Резервное копирование PasteFlow
            VStack(alignment: .leading, spacing: 12) {
                Text("backup.backup_json".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("backup.backup_json_desc".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                    
                    HStack(spacing: 12) {
                        Button(action: exportSnippetsJSON) {
                            Label("backup.export_json_btn".localized, systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: importSnippetsJSON) {
                            Label("backup.import_json_btn".localized, systemImage: "square.and.arrow.down")
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private func importClipyXML() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.xml, .plainText]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.message = "backup.select_xml_msg".localized
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url, let data = try? Data(contentsOf: url) {
                let success = ExportImportService.shared.importClipyXML(data: data, context: viewContext)
                DispatchQueue.main.async {
                    statusMessage = success ? "backup.success_xml".localized : "backup.error_xml".localized
                }
            }
        }
    }
    
    private func exportSnippetsJSON() {
        let fetchRequest: NSFetchRequest<CDSnippetFolder> = NSFetchRequest(entityName: "CDSnippetFolder")
        guard let folders = try? viewContext.fetch(fetchRequest),
              let data = ExportImportService.shared.exportSnippets(folders: folders) else {
            statusMessage = "backup.error_no_snippets".localized
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "PasteFlowSnippets.json"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? data.write(to: url)
                DispatchQueue.main.async {
                    statusMessage = "backup.success_export_json".localized + url.lastPathComponent
                }
            }
        }
    }
    
    private func importSnippetsJSON() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url, let data = try? Data(contentsOf: url) {
                let success = ExportImportService.shared.importSnippetsJSON(data: data, context: viewContext)
                DispatchQueue.main.async {
                    statusMessage = success ? "backup.success_import_json".localized : "backup.error_json".localized
                }
            }
        }
    }
}

// MARK: - Инструкция и Описание
struct HelpPrefsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("help.problem_title".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text("help.problem_desc1".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                
                Text("help.problem_desc2".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("help.features_title".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    HelpFeatureRow(
                        icon: "clock.arrow.2.circlepath",
                        title: "help.feat_hist_title".localized,
                        description: "help.feat_hist_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "eye.fill",
                        title: "help.feat_prev_title".localized,
                        description: "help.feat_prev_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "folder.fill",
                        title: "help.feat_group_title".localized,
                        description: "help.feat_group_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "doc.on.doc.fill",
                        title: "help.feat_snip_title".localized,
                        description: "help.feat_snip_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "checkmark.bubble.fill",
                        title: "help.feat_text_title".localized,
                        description: "help.feat_text_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "doc.on.doc.fill",
                        title: "help.feat_files_title".localized,
                        description: "help.feat_files_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "eye.slash.fill",
                        title: "help.feat_pause_title".localized,
                        description: "help.feat_pause_desc".localized
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "timer",
                        title: "help.feat_autohide_title".localized,
                        description: "help.feat_autohide_desc".localized
                    )
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
        }
    }
}

struct HelpFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20, height: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
