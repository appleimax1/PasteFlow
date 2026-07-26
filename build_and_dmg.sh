#!/bin/bash

# Выходим при любой ошибке
set -e

# Автоопределение папки: если скрипт запущен из корня репозитория,
# переходим в подпапку PasteFlow, где лежит проект
if [ -d "PasteFlow" ] && [ -f "PasteFlow/project.yml" ]; then
    echo "Определена корневая папка репозитория. Переходим в PasteFlow/..."
    cd PasteFlow
fi

# Проверяем и запускаем xcodegen перед сборкой, чтобы добавить новые ресурсы в проект Xcode
if command -v xcodegen >/dev/null 2>&1; then
    echo "=== 1. Регенерация проекта Xcode с помощью XcodeGen ==="
    xcodegen generate
else
    echo "Предупреждение: xcodegen не установлен."
fi

echo "=== 2. Очистка предыдущих сборок ==="
rm -rf ./build/Release
rm -f ../PasteFlow.dmg
rm -f ./PasteFlow.dmg

echo "=== 3. Сборка приложения в режиме Release ==="
xcodebuild -scheme PasteFlow -project PasteFlow.xcodeproj -configuration Release SYMROOT=$(pwd)/build build CODE_SIGNING_ALLOWED=NO

# Находим собранный .app файл
APP_PATH="./build/Release/PasteFlow.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Ошибка: Не удалось найти собранное приложение по пути $APP_PATH"
    exit 1
fi

echo "=== 4. Подготовка структуры DMG ==="
DMG_TEMP="./build/dmg_root"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Копируем приложение в будущий образ
cp -R "$APP_PATH" "$DMG_TEMP/"

# Создаем символическую ссылку на папку программы /Applications
ln -s /Applications "$DMG_TEMP/Applications"

echo "=== 5. Создание DMG образа ==="
hdiutil create -volname "PasteFlow v1.5" -srcfolder "$DMG_TEMP" -ov -format UDZO ./PasteFlow.dmg
echo "========================================="
echo "Готово! Образ успешно создан: $(pwd)/PasteFlow.dmg"

# Очищаем временную структуру
rm -rf "$DMG_TEMP"

echo "========================================="
