# PasteFlow

<p align="center">
  <img src="PasteFlow/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="PasteFlow Logo">
</p>

[Russian version below / Русская версия ниже](#русская-версия)

PasteFlow is a lightweight, powerful, and convenient clipboard manager and text assistant for macOS. It allows you to track your clipboard history, manage text templates/snippets, and instantly perform local spellchecking and punctuation correction. The application runs natively in the macOS menu bar, preserving system resources and keeping your workflow clean.

## Download & Installation

1. Download the latest version of the app from this link:
   👉 [**Download PasteFlow (Google Drive Folder)**](https://drive.google.com/drive/folders/1VSYy-SQL9Ki0fQ7HM7v-K-Q0Ux-MfcyU?usp=sharing)
2. Open the downloaded `.dmg` file and drag the application to your **Applications** folder.

### Bypassing macOS Gatekeeper (Security Warning)
Since the application is built without a paid Apple Developer ID certificate, macOS might block its execution with an "unidentified developer" warning.

To allow launching the application, open the **Terminal** app (Terminal.app) and run the following command:

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
* **Clipboard History**: Stores history of text, links, RTF, PDF, and images. Fast search and paste in one click.
* **Snippet Library**: Create folders and templates for frequently used text, commands, or links with macro support.
* **Text Assistant (Spellcheck & Punctuation)**: 
  * 100% local, offline text checking engine.
  * **Interactive Corrections**: Click any highlighted fix in the result pane to revert that specific word to the original text ("keep as is").
  * **In-Window Shortcuts**: Press **`Cmd + Enter`** (`⌘↵`) to copy the result instantly with visual green feedback, or press **`Esc`** to close the window.
  * **Flexible Close Settings**: Configure in Preferences whether to keep the entered text across window calls or automatically clear it when closing via `Esc`.

---

## Русская версия

PasteFlow — это легкий, мощный и удобный менеджер буфера обмена и помощник по проверке текста для macOS. Он позволяет хранить историю копирования, управлять библиотекой сниппетов (шаблонов текста) и мгновенно выполнять локальную проверку орфографии и пунктуации. Приложение работает из статус-бара macOS, не перегружая интерфейс и экономя ресурсы системы.

## Скачивание и установка

1. Скачайте последнюю версию приложения по ссылке:
   👉 [**Скачать PasteFlow (Папка Google Диск)**](https://drive.google.com/drive/folders/1VSYy-SQL9Ki0fQ7HM7v-K-Q0Ux-MfcyU?usp=sharing)
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
* **История копирования**: Хранение истории текстовых данных, ссылок, форматированного текста и изображений. Быстрый поиск и вставка в один клик.
* **Библиотека сниппетов**: Создание папок и шаблонов для часто используемых текстов, команд или ссылок с поддержкой макросов.
* **Проверка текста (Орфография и Пунктуация)**:
  * 100% локальный движок проверки текста, работающий без интернета.
  * **Интерактивная отмена правок**: Кликните на любое подсвеченное исправление в правом окне, чтобы вернуть исходное слово («оставить как есть»).
  * **Навигация и горячие клавиши**: Нажмите **`Cmd + Enter`** (`⌘↵`) для мгновенного копирования результата в буфер обмена с визуальной индикацией или клавишу **`Esc`** для закрытия окна.
  * **Гибкие настройки сценария**: В настройках можно выбрать: сохранять ли введенный текст при каждом вызове окна или автоматически очищать его при закрытии окна клавишей `Esc`.
