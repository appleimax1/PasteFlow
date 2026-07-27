# PasteFlow

<p align="center">
  <img src="PasteFlow/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="PasteFlow Logo">
</p>

[Russian version below / Русская версия ниже](#русская-версия)

PasteFlow is a lightweight, powerful, and convenient clipboard manager and text assistant for macOS. It allows you to track your clipboard history, manage text templates/snippets, and instantly perform local spellchecking and punctuation correction. The application runs natively in the macOS menu bar, preserving system resources and keeping your workflow clean.

## Download & Installation

### Option 1: Via Homebrew (Recommended)

You can easily install PasteFlow via Homebrew Cask:

```bash
brew tap appleimax1/pasteflow
brew install --cask pasteflow
```

### Option 2: Direct Download (.dmg)

1. Download the latest version from [GitHub Releases](https://github.com/appleimax1/PasteFlow/releases/latest) or [Google Drive Folder](https://drive.google.com/drive/folders/1VSYy-SQL9Ki0fQ7HM7v-K-Q0Ux-MfcyU?usp=sharing).
2. Open the downloaded `.dmg` file and drag the application to your **Applications** folder.

### Bypassing macOS Gatekeeper (Security Warning)
Since the application is built without a paid Apple Developer ID certificate, macOS might block its execution with an "unidentified developer" warning upon first manual run.

To allow launching the application, open the **Terminal** app (Terminal.app) and run:

```bash
sudo xattr -cr /Applications/PasteFlow.app
```

Once executed, the app will open without issues.

---

## Hotkeys

Global hotkeys allow instant access to PasteFlow features.

### Customization & Unassigning Shortcuts
You can customize or clear hotkeys at any time:
1. Open application Settings.
2. Go to the **Hotkeys** tab.
3. Click on the shortcut recording field for the desired action and press your key combination.
4. To unassign a shortcut and make it optional, click the **✕** button next to it.

---

## Key Features

* **Bilingual Interface**: Fully supports both **English** (default) and **Russian** languages. The interface language can be changed easily in the app preferences under the General tab.
* **Clipboard History**: Stores history of text, links, RTF, PDF, images, and **files/folders**. Fast search and instant paste with **`⌘1`**...**`⌘9`**, **`⌘0`** hotkeys for items 1–10.
* **Incognito Mode (Pause)**: Temporarily pause clipboard recording via the popup to protect sensitive passwords and data.
* **Auto-hiding**: The popup automatically hides after 15 seconds of inactivity.
* **Snippet Library**: Create folders and templates for frequently used text, commands, or links with macro support.
* **Text Assistant (Spellcheck & Punctuation)**: 
  * **Hunspell Engine**: Powered by Hunspell morphological spellchecker with bundled English and Russian dictionary files (`en_US` and `ru_RU`).
  * **Smart Typo Correction**: Uses advanced shape-matching algorithms and common word frequencies for accurate suggestions.
  * **Extended Punctuation & Typography**: Rules for conjunctions, introductory words, addresses, quotes («...»), em-dashes (—), and spacing.
  * 100% local, offline text checking engine.
  * **Interactive Corrections**: Click any highlighted fix in the result pane to revert that specific word to the original text ("keep as is").
  * **In-Window Shortcuts**: Press **`Cmd + Enter`** (`⌘↵`) to copy the result instantly with visual green feedback, or press **`Esc`** to close the window.
  * **Flexible Close Settings**: Configure in Preferences whether to keep the entered text across window calls or automatically clear it when closing via `Esc`.

---

## Русская версия

PasteFlow — это легкий, мощный и удобный менеджер буфера обмена и помощник по проверке текста для macOS. Он позволяет хранить историю копирования, управлять библиотекой сниппетов (шаблонов текста) и мгновенно выполнять локальную проверку орфографии и пунктуации. Приложение работает из статус-бара macOS, не перегружая интерфейс и экономя ресурсы системы.

## Скачивание и установка

### Способ 1: Через Homebrew (Рекомендуется)

Вы можете легко установить PasteFlow с помощью Homebrew Cask:

```bash
brew tap appleimax1/pasteflow
brew install --cask pasteflow
```

### Способ 2: Прямая загрузка (.dmg)

1. Скачайте последнюю версию со страницы [GitHub Releases](https://github.com/appleimax1/PasteFlow/releases/latest) или из [папки Google Диск](https://drive.google.com/drive/folders/1VSYy-SQL9Ki0fQ7HM7v-K-Q0Ux-MfcyU?usp=sharing).
2. Откройте загруженный файл `.dmg` и перетащите приложение в папку **Программы** (`Applications`).

### Обход предупреждения безопасности macOS (Gatekeeper)
Так как приложение собрано без платного сертификата Apple Developer ID, macOS может заблокировать его запуск с предупреждением о «неизвестном разработчике».

Чтобы разрешить запуск приложения, откройте программу **Терминал** (Terminal.app) и выполните следующую команду:

```bash
sudo xattr -cr /Applications/PasteFlow.app
```

После выполнения этой команды приложение успешно запустится.

---

## Управление горячими клавишами

Глобальные комбинации клавиш обеспечивают мгновенный доступ к функциям PasteFlow.

### Кастомизация и отмена горячих клавиш
Вы можете в любой момент изменить или отменить комбинации клавиш под свои предпочтения:
1. Откройте настройки программы и перейдите во вкладку **Горячие клавиши**.
2. Нажмите на поле ввода для нужного действия и зажмите комбинацию на клавиатуре.
3. Чтобы сделать вызов опциональным и отменить сочетание клавиш, нажмите на значок **✕** рядом с ним.

---

## Ключевой функционал приложения

* **Двуязычный интерфейс**: Полная поддержка **английского** (по умолчанию) и **русского** языков. Язык интерфейса переключается во вкладке «Основные».
* **История копирования**: Хранение истории текстовых данных, ссылок, форматированного текста, изображений и **файлов**. Быстрый поиск и мгновенная вставка по горячим клавишам **`⌘1`**...**`⌘9`**, **`⌘0`** для записей с 1-й по 10-ю.
* **Режим Инкогнито (Пауза)**: Приостанавливайте запись истории прямо из меню, чтобы безопасно копировать пароли.
* **Умное скрытие**: Окно истории автоматически исчезает при отсутствии активности в течение 15 секунд.
* **Библиотека сниппетов**: Создание папок и шаблонов для часто используемых текстов, команд или ссылок с поддержкой макросов.
* **Проверка текста (Орфография и Пунктуация)**:
  * **Движок Hunspell**: Полноценная локальная проверка орфографии на базе морфологического движка Hunspell со встроенными словарями английского и русского языков (`en_US` и `ru_RU`).
  * **Умные алгоритмы**: Улучшенный алгоритм подбора слов на основе формы слова и частотных словарей для исправления опечаток.
  * **Расширенная пунктуация и типографика**: Поддержка правил для союзов, вводных слов, обращений, парных кавычек («...»), длинного тире (—) и коррекции пробелов.
  * 100% локальный движок проверки текста, работающий без интернета.
  * **Интерактивная отмена правок**: Кликните на любое подсвеченное исправление в правом окне, чтобы вернуть исходное слово («оставить как есть»).
  * **Навигация и горячие клавиши**: Нажмите **`Cmd + Enter`** (`⌘↵`) для мгновенного копирования результата в буфер обмена с визуальной индикацией или клавишу **`Esc`** для закрытия окна.
  * **Гибкие настройки сценария**: В настройках можно выбрать: сохранять ли введенный текст при каждом вызове окна или автоматически очищать его при закрытии окна клавишей `Esc`.
