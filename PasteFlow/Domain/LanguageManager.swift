import SwiftUI

enum Language: String, CaseIterable, Identifiable {
    case en = "English"
    case ru = "Русский"
    
    var id: String { rawValue }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("PasteFlow.Language") var currentLanguage: String = "en"
    
    private let translations: [String: [String: String]] = [
        "en": [
            // Tabs
            "tab.general": "General",
            "tab.menu": "Menu & View",
            "tab.types": "Data Types",
            "tab.exclusions": "Exclusions",
            "tab.hotkeys": "Hotkeys",
            "tab.text_assistant": "Text Assistant",
            "tab.backup": "Backups",
            "tab.help": "Help",
            "settings": "Settings",
            "app.smart_clipboard_manager": "Smart Clipboard Manager",
            
            // General
            "general.app_behavior": "App Behavior",
            "general.play_sound": "Play sound on paste",
            "general.launch_at_login": "Launch PasteFlow at login",
            "general.history_storage": "Clipboard History Storage",
            "general.max_items": "Maximum number of items:",
            "general.items_10": "10 items",
            "general.items_20": "20 items",
            "general.items_40": "40 items",
            "general.items_50": "50 items",
            "general.items_100": "100 items",
            "general.items_200": "200 items",
            "general.limit_desc": "The oldest unpinned clipboard entries will be automatically deleted when the limit is exceeded.",
            "general.data_management": "Data Management",
            "general.clear_history_title": "Clear clipboard history",
            "general.clear_history_desc": "Deletes all unpinned items from the clipboard history. Pinned items will be preserved.",
            "general.clear_history_btn": "Clear history",
            "general.clear_history_confirm_title": "Clear clipboard history?",
            "general.clear_history_confirm_desc": "Are you sure you want to delete all unpinned items from the history? This action cannot be undone.",
            "general.clear": "Clear",
            "general.cancel": "Cancel",
            "general.language": "Language",
            "general.interface_language": "Interface Language",
            
            // Menu
            "menu.list_appearance": "List Appearance",
            "menu.group_subfolders": "Group items into subfolders:",
            "menu.group_disabled": "Disabled (flat list)",
            "menu.group_10": "10 items per folder",
            "menu.group_20": "20 items per folder",
            "menu.group_30": "30 items per folder",
            "menu.show_preview": "Show preview popup on hover",
            
            // Data Types
            "types.supported_types": "Supported Clipboard Data Types",
            "types.plain_text": "Plain Text",
            "types.rich_text": "Rich Text (RTF / HTML)",
            "types.images": "Images (PNG / JPEG / TIFF)",
            "types.pdf": "PDF Documents",
            "types.files": "Files and Folders (Finder)",
            
            // Exclusions
            "exclusions.blacklist": "Application Blacklist",
            "exclusions.desc": "Copied content from specified applications will be automatically ignored to protect passwords and confidential data.",
            "exclusions.bundle_placeholder": "Bundle Identifier (e.g., com.1password.1password)",
            "exclusions.add": "Add",
            
            // Hotkeys
            "hotkeys.global_shortcuts": "Global Hotkeys",
            "hotkeys.history_popup": "Clipboard history (popup menu):",
            "hotkeys.app_settings": "App settings (preferences window):",
            "hotkeys.snippets_popup": "Snippets library (popup menu):",
            "hotkeys.record_desc": "Click on a shortcut and press the desired combination on your keyboard.",
            "hotkeys.press_keys": "Press keys...",
            "hotkeys.reset_tooltip": "Reset to default",
            
            // Backup
            "backup.import_xml": "Import from XML",
            "backup.import_xml_desc": "Select the XML file of your snippet export. All folders and snippets will be automatically added to your PasteFlow library.",
            "backup.import_xml_btn": "Import snippets (XML)...",
            "backup.backup_json": "PasteFlow Backup (JSON)",
            "backup.backup_json_desc": "Export your PasteFlow snippet library to a JSON file or restore it from a backup.",
            "backup.export_json_btn": "Export to JSON...",
            "backup.import_json_btn": "Import from JSON...",
            "backup.success_xml": "Snippets successfully imported!",
            "backup.error_xml": "Error reading XML format.",
            "backup.error_no_snippets": "No snippets found for export.",
            "backup.success_export_json": "Snippets successfully exported to ",
            "backup.success_import_json": "Snippets successfully imported.",
            "backup.error_json": "Error reading JSON file.",
            "backup.select_xml_msg": "Select snippets XML export file",
            
            // Help
            "help.problem_title": "What problem does PasteFlow solve?",
            "help.problem_desc1": "The standard macOS clipboard can only store a single copied entry. With every new copy action (Cmd+C), the old data is lost forever. This is highly inconvenient when working with multiple text fragments, code, images, or links.",
            "help.problem_desc2": "PasteFlow solves this problem by saving your clipboard history in the background and providing instant access to it at any time.",
            "help.features_title": "Key Features:",
            "help.feat_hist_title": "Clipboard History",
            "help.feat_hist_desc": "Stores text, images, rich text, and files. The history size is easily customized in the \"General\" tab.",
            "help.feat_prev_title": "Intelligent Preview",
            "help.feat_prev_desc": "Hovering over a history item opens a floating preview panel showing its full content.",
            "help.feat_group_title": "Smart Grouping",
            "help.feat_group_desc": "Items are automatically split into history folders (e.g., 10 or 20 items per folder) to save screen space.",
            "help.feat_snip_title": "Snippet Library",
            "help.feat_snip_desc": "Create templates for frequently used texts and paste them with a single click via the snippets menu.",
            
            // Main / Popup UI
            "popup.history": "History",
            "popup.snippets": "Snippets",
            "popup.settings": "Settings",
            "popup.quit_tooltip": "Quit PasteFlow",
            "popup.search_history": "Search history...",
            "popup.history_empty": "History is empty",
            "popup.nothing_found": "Nothing found",
            "popup.history_folder_range": "History %d - %d",
            "popup.paste": "Paste",
            "popup.paste_plain": "Paste as Plain Text",
            "popup.unpin": "Unpin",
            "popup.pin": "Pin to Top",
            "popup.delete": "Delete",
            "popup.search_snippets": "Search snippets...",
            "popup.snippets_empty": "No Snippets",
            "popup.snippets_empty_desc": "Use the Snippet Manager in the settings window to create templates or import them from XML.",
            
            // Snippets Library
            "snippets.untitled": "Untitled",
            "snippets.folders": "Folders",
            "snippets.new_folder": "New Folder",
            "snippets.delete_folder": "Delete Folder",
            "snippets.folders_title": "Snippet Folders",
            "snippets.snippets_in_folder": "Snippets in Folder",
            "snippets.delete_snippet": "Delete Snippet",
            "snippets.new_snippet": "New Snippet",
            "snippets.select_folder_prompt": "Select or Create a Folder",
            "snippets.select_snippet_prompt": "Select a Snippet to Edit",
            "snippets.snippet_name": "Snippet Name",
            "snippets.name_placeholder": "e.g., Greeting",
            "snippets.keyword": "Keyword",
            "snippets.keyword_placeholder": "e.g., ;;email",
            "snippets.insert_tag": "Insert dynamic tag:",
            "snippets.template_text": "Template Text",
            "snippets.live_preview": "Live Preview",
            "snippets.empty_snippet": "(Empty snippet)",
            "snippets.default_folder_name": "New Folder %d",
            "snippets.default_snippet_name": "New Snippet",
            "snippets.default_snippet_content": "Hello {CLIPBOARD}",
            
            // Hover preview
            "hover.chars": "chars",
            "hover.paste": "Enter — paste",
            "hover.plain_text": "Shift+Enter — plain text",
            
            // CoreData items
            "core.image": "Image",
            "core.file": "File",
            "core.files": "%d Files (%@, ...)",
            "core.clipboard_item": "Clipboard Item",
            
            // MenuBar controller
            "menu.title_preferences": "PasteFlow Preferences",
            "menu.title_snippets": "Snippet Manager",
            
            // Text Assistant & Hotkeys
            "hotkeys.text_assistant": "Spellcheck & Punctuation assistant:",
            "hotkeys.unassigned": "Unassigned",
            "hotkeys.clear_tooltip": "Clear shortcut",
            "menu.text_assistant": "Spellcheck & Punctuation...",
            "text_assistant.title": "Spellcheck & Punctuation",
            "text_assistant.title_short": "Spellcheck",
            "text_assistant.input_placeholder": "Enter or paste text here...",
            "text_assistant.result_placeholder": "Corrected text will appear here...",
            "text_assistant.check_btn": "Check Text",
            "text_assistant.copy_btn": "Copy Result",
            "text_assistant.paste_input_btn": "Paste from Clipboard",
            "text_assistant.replace_active_btn": "Replace in App",
            "text_assistant.clear_btn": "Clear",
            "text_assistant.stats": "%d chars • %d words • %d fixes",
            "text_assistant.hints": "💡 Click any highlighted correction to revert to original word",
            "text_assistant.replaced_toast": "✓ Inserted into active app!",
            "text_assistant.pref_title": "Text Assistant Settings",
            "text_assistant.pref_behavior_label": "Behavior of input text on closing window:",
            "text_assistant.pref_option_keep": "Keep entered text across window calls",
            "text_assistant.pref_option_clear": "Clear input text upon closing window (Esc)",
            "text_assistant.pref_desc": "Select whether PasteFlow should remember previously entered text or clear it when closing the window with Esc.",
            "help.feat_text_title": "Spellcheck & Punctuation",
            "help.feat_text_desc": "Quick spellcheck & punctuation analysis. You can assign your custom hotkey to trigger this feature in the Hotkeys tab in Settings. 100% local checking, interactive edit reverting on click, and fast copying via Cmd+Enter."
        ],
        "ru": [
            // Tabs
            "tab.general": "Основные",
            "tab.menu": "Меню и Вид",
            "tab.types": "Типы данных",
            "tab.exclusions": "Исключения",
            "tab.hotkeys": "Горячие клавиши",
            "tab.text_assistant": "Проверка текста",
            "tab.backup": "Резервные копии",
            "tab.help": "Инструкция",
            "settings": "Настройки",
            "app.smart_clipboard_manager": "Умный менеджер буфера обмена",
            
            // General
            "general.app_behavior": "Поведение приложения",
            "general.play_sound": "Воспроизводить звук при вставке",
            "general.launch_at_login": "Запускать PasteFlow при входе в систему",
            "general.history_storage": "Хранение истории буфера обмена",
            "general.max_items": "Максимальное количество элементов:",
            "general.items_10": "10 элементов",
            "general.items_20": "20 элементов",
            "general.items_40": "40 элементов",
            "general.items_50": "50 элементов",
            "general.items_100": "100 элементов",
            "general.items_200": "200 элементов",
            "general.limit_desc": "Самые старые незакреплённые записи буфера будут автоматически удаляться при превышении указанного лимита.",
            "general.data_management": "Управление данными",
            "general.clear_history_title": "Очистить историю буфера",
            "general.clear_history_desc": "Удаляет все незакреплённые элементы из истории буфера обмена. Закреплённые элементы сохранятся.",
            "general.clear_history_btn": "Очистить историю",
            "general.clear_history_confirm_title": "Очистить историю буфера обмена?",
            "general.clear_history_confirm_desc": "Вы уверены, что хотите удалить все незакреплённые элементы из истории буфера? Это действие нельзя будет отменить.",
            "general.clear": "Очистить",
            "general.cancel": "Отмена",
            "general.language": "Выбор языка",
            "general.interface_language": "Язык интерфейса",
            
            // Menu
            "menu.list_appearance": "Оформление списка элементов",
            "menu.group_subfolders": "Группировать элементы в подпапки:",
            "menu.group_disabled": "Отключено (единый список)",
            "menu.group_10": "По 10 элементов в папке",
            "menu.group_20": "По 20 элементов в папке",
            "menu.group_30": "По 30 элементов в папке",
            "menu.show_preview": "Показывать всплывающую карточку предпросмотра при наведении",
            
            // Data Types
            "types.supported_types": "Поддерживаемые типы данных буфера обмена",
            "types.plain_text": "Обычный текст (Plain Text)",
            "types.rich_text": "Форматированный текст (RTF / HTML)",
            "types.images": "Изображения (PNG / JPEG / TIFF)",
            "types.pdf": "Документы PDF",
            "types.files": "Файлы и папки Finder",
            
            // Exclusions
            "exclusions.blacklist": "Черный список приложений",
            "exclusions.desc": "Скопированный контент из указанных приложений будет автоматически игнорироваться для защиты паролей и конфиденциальных данных.",
            "exclusions.bundle_placeholder": "Идентификатор (например, com.1password.1password)",
            "exclusions.add": "Добавить",
            
            // Hotkeys
            "hotkeys.global_shortcuts": "Глобальные комбинации клавиш",
            "hotkeys.history_popup": "История буфера обмена (всплывающее меню):",
            "hotkeys.app_settings": "Настройки приложения (окно настроек):",
            "hotkeys.snippets_popup": "Библиотека сниппетов (всплывающее меню):",
            "hotkeys.text_assistant": "Проверка орфографии и пунктуации:",
            "hotkeys.unassigned": "Не назначено",
            "hotkeys.clear_tooltip": "Очистить сочетание",
            "hotkeys.record_desc": "Нажмите на сочетание клавиш и зажмите нужную комбинацию на клавиатуре.",
            "hotkeys.press_keys": "Нажмите клавиши...",
            "hotkeys.reset_tooltip": "Сбросить на значение по умолчанию",
            
            // Backup
            "backup.import_xml": "Импорт из XML",
            "backup.import_xml_desc": "Выберите XML-файл экспорта сниппетов. Все папки и сниппеты будут автоматически добавлены в вашу библиотеку PasteFlow.",
            "backup.import_xml_btn": "Импортировать сниппеты (XML)...",
            "backup.backup_json": "Резервное копирование PasteFlow (JSON)",
            "backup.backup_json_desc": "Экспортируйте библиотеку сниппетов PasteFlow в файл JSON или восстановите её из копии.",
            "backup.export_json_btn": "Экспорт в JSON...",
            "backup.import_json_btn": "Импорт из JSON...",
            "backup.success_xml": "Сниппеты успешно импортированы!",
            "backup.error_xml": "Ошибка чтения формата XML.",
            "backup.error_no_snippets": "Сниппеты для экспорта не найдены.",
            "backup.success_export_json": "Сниппеты успешно экспортированы в ",
            "backup.success_import_json": "Сниппеты успешно импортированы.",
            "backup.error_json": "Ошибка чтения файла JSON.",
            "backup.select_xml_msg": "Выберите XML-файл экспорта сниппетов",
            
            // Help
            "help.problem_title": "Какую проблему решает PasteFlow?",
            "help.problem_desc1": "Стандартный буфер обмена macOS умеет хранить только одну скопированную запись. При каждом новом копировании (Cmd+C) старые данные бесследно стираются. Это крайне неудобно при работе с несколькими фрагментами текста, кодом, изображениями или ссылками.",
            "help.problem_desc2": "PasteFlow решает эту проблему, сохраняя историю вашего буфера обмена в фоновом режиме и предоставляя к ней мгновенный доступ в любой момент.",
            "help.features_title": "Ключевой функционал:",
            "help.feat_hist_title": "История буфера обмена",
            "help.feat_hist_desc": "Хранит тексты, изображения, форматированный текст и файлы. Размер истории легко настраивается во вкладке «Основные».",
            "help.feat_prev_title": "Интеллектуальное превью",
            "help.feat_prev_desc": "При наведении курсора на элемент истории открывается плавающее окно предпросмотра с полным содержимым.",
            "help.feat_group_title": "Умная группировка",
            "help.feat_group_desc": "Элементы автоматически разбиваются на папки истории (например, по 10 или 20 элементов) для экономии места на экране.",
            "help.feat_snip_title": "Библиотека сниппетов",
            "help.feat_snip_desc": "Создавайте шаблоны часто используемых текстов и вставляйте их в один клик через меню сниппетов.",
            
            // Main / Popup UI
            "popup.history": "История",
            "popup.snippets": "Сниппеты",
            "popup.settings": "Настройки",
            "popup.quit_tooltip": "Завершить PasteFlow",
            "popup.search_history": "Поиск в истории...",
            "popup.history_empty": "История пуста",
            "popup.nothing_found": "Ничего не найдено",
            "popup.history_folder_range": "История %d - %d",
            "popup.paste": "Вставить",
            "popup.paste_plain": "Вставить как обычный текст",
            "popup.unpin": "Открепить",
            "popup.pin": "Закрепить наверху",
            "popup.delete": "Удалить",
            "popup.search_snippets": "Поиск в сниппетах...",
            "popup.snippets_empty": "Сниппеты отсутствуют",
            "popup.snippets_empty_desc": "Используйте Менеджер сниппетов в окне настроек для создания шаблонов или импорта из XML.",
            
            // Snippets Library
            "snippets.untitled": "Без названия",
            "snippets.folders": "Папки",
            "snippets.new_folder": "Новая папка",
            "snippets.delete_folder": "Удалить папку",
            "snippets.folders_title": "Папки сниппетов",
            "snippets.snippets_in_folder": "Сниппеты в папке",
            "snippets.delete_snippet": "Удалить сниппет",
            "snippets.new_snippet": "Новый сниппет",
            "snippets.select_folder_prompt": "Выберите или создайте папку",
            "snippets.select_snippet_prompt": "Выберите сниппет для редактирования",
            "snippets.snippet_name": "Название сниппета",
            "snippets.name_placeholder": "Например, Приветствие",
            "snippets.keyword": "Ключевое слово",
            "snippets.keyword_placeholder": "например, ;;email",
            "snippets.insert_tag": "Вставить динамический тег:",
            "snippets.template_text": "Текст шаблона",
            "snippets.live_preview": "Живой предпросмотр результата",
            "snippets.empty_snippet": "(Пустой сниппет)",
            "snippets.default_folder_name": "Новая папка %d",
            "snippets.default_snippet_name": "Новый сниппет",
            "snippets.default_snippet_content": "Привет {CLIPBOARD}",
            
            // Hover preview
            "hover.chars": "симв.",
            "hover.paste": "Enter — вставить",
            "hover.plain_text": "Shift+Enter — текст",
            
            // CoreData items
            "core.image": "Изображение",
            "core.file": "Файл",
            "core.files": "Файлов: %d (%@, ...)",
            "core.clipboard_item": "Элемент буфера",
            
            // MenuBar controller & Text Assistant
            "menu.title_preferences": "Настройки PasteFlow",
            "menu.title_snippets": "Менеджер сниппетов",
            "menu.text_assistant": "Проверка орфографии и пунктуации...",
            "text_assistant.title": "Проверка текста",
            "text_assistant.title_short": "Проверка",
            "text_assistant.input_placeholder": "Введите или вставьте текст для проверки...",
            "text_assistant.result_placeholder": "Результат проверки появится здесь...",
            "text_assistant.check_btn": "Проверить текст",
            "text_assistant.copy_btn": "Скопировать результат",
            "text_assistant.paste_input_btn": "Вставить из буфера",
            "text_assistant.replace_active_btn": "Заменить в приложении",
            "text_assistant.clear_btn": "Очистить",
            "text_assistant.stats": "%d симв. • %d слов • %d исправлений",
            "text_assistant.hints": "💡 Кликните на подсвеченную правку, чтобы вернуть исходное слово",
            "text_assistant.replaced_toast": "✓ Текст вставлен в приложение!",
            "text_assistant.pref_title": "Настройки проверки текста",
            "text_assistant.pref_behavior_label": "Поведение исходного текста при закрытии окна:",
            "text_assistant.pref_option_keep": "Сохранять заполненный текст при каждом вызове окна",
            "text_assistant.pref_option_clear": "Очищать исходный текст при закрытии окна (через Esc)",
            "text_assistant.pref_desc": "Выберите, должен ли PasteFlow запоминать ранее введенный текст или очищать его при закрытии окна клавишей Esc.",
            "help.feat_text_title": "Проверка орфографии и пунктуации",
            "help.feat_text_desc": "Быстрый анализ текста на орфографию и пунктуацию. Для запуска вы можете назначить свои горячие клавиши в разделе «Горячие клавиши» в настройках. 100% локальная проверка, интерактивная отмена правок по клику и быстрое копирование по Cmd+Enter."
        ]
    ]
    
    func tr(_ key: String) -> String {
        return translations[currentLanguage]?[key] ?? key
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.tr(self)
    }
}
