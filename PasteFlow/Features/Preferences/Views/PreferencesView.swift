import SwiftUI
import ServiceManagement

enum PreferenceTab: String, CaseIterable, Identifiable {
    case general = "Основные"
    case menu = "Меню и Вид"
    case types = "Типы данных"
    case exclusions = "Исключения"
    case hotkeys = "Горячие клавиши"
    case backup = "Резервные копии"
    case help = "Инструкция"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .menu: return "line.3.horizontal.circle.fill"
        case .types: return "doc.on.doc.fill"
        case .exclusions: return "hand.raised.fill"
        case .hotkeys: return "keyboard.fill"
        case .backup: return "arrow.triangle.2.circlepath.circle.fill"
        case .help: return "questionmark.circle.fill"
        }
    }
}

struct PreferencesView: View {
    @State private var selectedTab: PreferenceTab = .general
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("Настройки")
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
                            
                            Text(tab.rawValue)
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
                    Text("PasteFlow v1.2")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Умный менеджер буфера обмена")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
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
                    Text(selectedTab.rawValue)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Поведение приложения")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Воспроизводить звук при вставке", isOn: $playSound)
                        .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle("Запускать PasteFlow при входе в систему", isOn: $launchAtLogin)
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
                                    print("Ошибка автозапуска: \(error)")
                                }
                            }
                        }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Хранение истории буфера обмена")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("Максимальное количество элементов:")
                            .font(.system(size: 13))
                        
                        Picker("", selection: $maxHistorySize) {
                            Text("10 элементов").tag(10)
                            Text("20 элементов").tag(20)
                            Text("40 элементов").tag(40)
                            Text("50 элементов").tag(50)
                            Text("100 элементов").tag(100)
                            Text("200 элементов").tag(200)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                    
                    Text("Самые старые незакреплённые записи буфера будут автоматически удаляться при превышении указанного лимита.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Управление данными")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Очистить историю буфера")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Удаляет все незакреплённые элементы из истории буфера обмена. Закреплённые элементы сохранятся.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Очистить историю") {
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
                title: Text("Очистить историю буфера обмена?"),
                message: Text("Вы уверены, что хотите удалить все незакреплённые элементы из истории буфера? Это действие нельзя будет отменить."),
                primaryButton: .destructive(Text("Очистить")) {
                    ClipboardHistoryManager.shared.clearHistory()
                },
                secondaryButton: .cancel(Text("Отмена"))
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
                Text("Оформление списка элементов")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("Группировать элементы в подпапки:")
                            .font(.system(size: 13))
                        
                        Picker("", selection: $folderGroupingSize) {
                            Text("Отключено (единый список)").tag(0)
                            Text("По 10 элементов в папке").tag(10)
                            Text("По 20 элементов в папке").tag(20)
                            Text("По 30 элементов в папке").tag(30)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 220)
                    }
                    
                    Divider()
                    
                    Toggle("Показывать всплывающую карточку предпросмотра при наведении", isOn: $showTooltips)
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
                Text("Поддерживаемые типы данных буфера обмена")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Обычный текст (Plain Text)", isOn: $enableText)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("Форматированный текст (RTF / HTML)", isOn: $enableRTF)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("Изображения (PNG / JPEG / TIFF)", isOn: $enableImages)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("Документы PDF", isOn: $enablePDF)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("Файлы и папки Finder", isOn: $enableFiles)
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
            Text("Черный список приложений")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Скопированный контент из указанных приложений будет автоматически игнорироваться для защиты паролей и конфиденциальных данных.")
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
                    TextField("Идентификатор (например, com.1password.1password)", text: $newBundleID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Добавить") {
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
struct HotkeysPrefsTab: View {
    @ObservedObject private var shortcutMgr = ShortcutManager.shared
    @State private var recordingTarget: Int? = nil // 0: Main/History, 1: Preferences, 2: Snippets
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Глобальные комбинации клавиш")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    // Option + Cmd + V: История буфера обмена
                    HotkeyRecorderRow(
                        label: "История буфера обмена (всплывающее меню):",
                        display: shortcutMgr.mainHotkeyDisplay,
                        isRecording: recordingTarget == 0,
                        onStartRecord: { startRecording(target: 0) },
                        onReset: { resetHotkey(target: 0) }
                    )
                    
                    Divider()
                    
                    // Option + Cmd + H: Настройки программы
                    HotkeyRecorderRow(
                        label: "Настройки приложения (окно настроек):",
                        display: shortcutMgr.historyHotkeyDisplay,
                        isRecording: recordingTarget == 1,
                        onStartRecord: { startRecording(target: 1) },
                        onReset: { resetHotkey(target: 1) }
                    )
                    
                    Divider()
                    
                    // Option + Cmd + S: Библиотека сниппетов
                    HotkeyRecorderRow(
                        label: "Библиотека сниппетов (всплывающее меню):",
                        display: shortcutMgr.snippetsHotkeyDisplay,
                        isRecording: recordingTarget == 2,
                        onStartRecord: { startRecording(target: 2) },
                        onReset: { resetHotkey(target: 2) }
                    )
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            Text("Нажмите на сочетание клавиш и зажмите нужную комбинацию на клавиатуре.")
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
        if target == 0 {
            shortcutMgr.saveMainHotkey(keyCode: 9, modifiers: optCmd) // ⌥⌘V
        } else if target == 1 {
            shortcutMgr.saveHistoryHotkey(keyCode: 4, modifiers: optCmd) // ⌥⌘H
        } else if target == 2 {
            shortcutMgr.saveSnippetsHotkey(keyCode: 1, modifiers: optCmd) // ⌥⌘S
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
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onStartRecord) {
                    Text(isRecording ? "Нажмите клавиши..." : display)
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
                
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Сбросить на значение по умолчанию")
            }
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
                Text("Импорт из XML")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Выберите XML-файл экспорта сниппетов. Все папки и сниппеты будут автоматически добавлены в вашу библиотеку PasteFlow.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                    
                    Button(action: importClipyXML) {
                        Label("Импортировать сниппеты (XML)...", systemImage: "doc.badge.plus")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            // Резервное копирование PasteFlow
            VStack(alignment: .leading, spacing: 12) {
                Text("Резервное копирование PasteFlow (JSON)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Экспортируйте библиотеку сниппетов PasteFlow в файл JSON или восстановите её из копии.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                    
                    HStack(spacing: 12) {
                        Button(action: exportSnippetsJSON) {
                            Label("Экспорт в JSON...", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: importSnippetsJSON) {
                            Label("Импорт из JSON...", systemImage: "square.and.arrow.down")
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
        openPanel.message = "Выберите XML-файл экспорта сниппетов"
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url, let data = try? Data(contentsOf: url) {
                let success = ExportImportService.shared.importClipyXML(data: data, context: viewContext)
                DispatchQueue.main.async {
                    statusMessage = success ? "Сниппеты успешно импортированы!" : "Ошибка чтения формата XML."
                }
            }
        }
    }
    
    private func exportSnippetsJSON() {
        let fetchRequest: NSFetchRequest<CDSnippetFolder> = NSFetchRequest(entityName: "CDSnippetFolder")
        guard let folders = try? viewContext.fetch(fetchRequest),
              let data = ExportImportService.shared.exportSnippets(folders: folders) else {
            statusMessage = "Сниппеты для экспорта не найдены."
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "PasteFlowSnippets.json"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? data.write(to: url)
                DispatchQueue.main.async {
                    statusMessage = "Сниппеты успешно экспортированы в \(url.lastPathComponent)."
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
                    statusMessage = success ? "Сниппеты успешно импортированы." : "Ошибка чтения файла JSON."
                }
            }
        }
    }
}

// MARK: - Инструкция и Описание
struct HelpPrefsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Раздел: Потребность и Назначение
            VStack(alignment: .leading, spacing: 8) {
                Text("Какую проблему решает PasteFlow?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text("Стандартный буфер обмена macOS умеет хранить только одну скопированную запись. При каждом новом копировании (Cmd+C) старые данные бесследно стираются. Это крайне неудобно при работе с несколькими фрагментами текста, кодом, изображениями или ссылками.")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                
                Text("PasteFlow решает эту проблему, сохраняя историю вашего буфера обмена в фоновом режиме и предоставляя к ней мгновенный доступ в любой момент.")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
            
            // Раздел: Функционал
            VStack(alignment: .leading, spacing: 12) {
                Text("Ключевой функционал:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    HelpFeatureRow(
                        icon: "clock.arrow.2.circlepath",
                        title: "История буфера обмена",
                        description: "Хранит тексты, изображения, форматированный текст и файлы. Размер истории легко настраивается во вкладке «Основные»."
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "eye.fill",
                        title: "Интеллектуальное превью",
                        description: "При наведении курсора на элемент истории открывается плавающее окно предпросмотра с полным содержимым."
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "folder.fill",
                        title: "Умная группировка",
                        description: "Элементы автоматически разбиваются на папки истории (например, по 10 или 20 элементов) для экономии места на экране."
                    )
                    
                    Divider()
                    
                    HelpFeatureRow(
                        icon: "doc.on.doc.fill",
                        title: "Библиотека сниппетов",
                        description: "Создавайте шаблоны часто используемых текстов и вставляйте их в один клик через меню сниппетов."
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
