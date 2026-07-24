# PasteFlow

<p align="center">
  <img src="PasteFlow/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="PasteFlow Logo">
</p>

[Russian version below / Русская версия ниже](#русская-версия)

PasteFlow is a lightweight and convenient clipboard manager for macOS that allows you to keep track of your clipboard history and quickly manage text snippets (templates). The application runs directly from the macOS menu bar, keeping the interface clean and saving system resources.

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

The following hotkeys are used by default to access key features:

* **`Shift + Cmd + V`** — Open the main clipboard history popup.
* **`Shift + Cmd + B`** — Open the snippets popup tab for quick template insertion.
* **`Shift + Cmd + H`** — Open the application settings.

### Customization
You can customize these shortcuts at any time:
1. Go to the application settings (**`Shift + Cmd + H`**).
2. Click on the hotkey recording field for the respective action.
3. Press your new key combination on the keyboard to automatically save it.

---

## Features

* **Bilingual Interface**: Fully supports both **English** (default) and **Russian** languages. The interface language can be changed easily in the app preferences under the General tab.
* **Clipboard History**: Stores history of text, links, and images. Fast search and paste in one click.
* **Snippet Library**: Create folders and templates for frequently used text, commands, or links with macro support.
* **App Exclusion List**: Specify applications from which the clipboard history should not be recorded (e.g., password managers).

---

## Русская версия

PasteFlow — это легкий и удобный менеджер буфера обмена для macOS, который позволяет отслеживать историю копирования и быстро управлять сниппетами (шаблонами текста). Приложение работает из статус-бара macOS, не перегружая интерфейс и экономя ресурсы системы.

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

Для быстрого доступа к функциям приложения используются следующие горячие клавиши по умолчанию:

* **`Shift + Cmd + V`** — Открыть главное окно истории буфера обмена.
* **`Shift + Cmd + B`** — Открыть вкладку с вашими сниппетами для быстрой вставки шаблонов.
* **`Shift + Cmd + H`** — Открыть окно настроек приложения.

### Персонализация
Вы можете в любой момент изменить стандартные сочетания клавиш под себя. Для этого:
1. Перейдите в настройки программы (**`Shift + Cmd + H`**).
2. Нажмите на поле ввода горячей клавиши для соответствующей функции.
3. Нажмите новое сочетание клавиш на клавиатуре, и оно автоматически сохранится.

---

## Функционал приложения

* **Двуязычный интерфейс**: Полная поддержка **английского** (по умолчанию) и **русского** языков. Язык интерфейса можно легко переключить в настройках приложения во вкладке «Основные».
* **История копирования**: Хранение истории текстовых данных, ссылок и изображений. Быстрый поиск и вставка в один клик.
* **Библиотека сниппетов**: Создание папок и шаблонов для часто используемых текстов, команд или ссылок с поддержкой макросов.
* **Черный список приложений**: Возможность указать приложения, из которых буфер обмена не должен сохраняться (например, менеджеры паролей).
