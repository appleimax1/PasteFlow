#!/bin/bash
SRC="/Users/Timur/.gemini/antigravity-ide/brain/76214c78-33d2-4e66-9709-240198ffae92/pasteflow_logo_clip_1784922889350.png"
DEST="PasteFlow/PasteFlow/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$DEST"

# Копируем файл во временный рабочий каталог (где есть доступ)
cp "$SRC" ./logo_source.png

# Запускаем sips на локальном файле
sips -z 16 16 ./logo_source.png --out "$DEST/icon_16x16.png"
sips -z 32 32 ./logo_source.png --out "$DEST/icon_16x16@2x.png"
sips -z 32 32 ./logo_source.png --out "$DEST/icon_32x32.png"
sips -z 64 64 ./logo_source.png --out "$DEST/icon_32x32@2x.png"
sips -z 128 128 ./logo_source.png --out "$DEST/icon_128x128.png"
sips -z 256 256 ./logo_source.png --out "$DEST/icon_128x128@2x.png"
sips -z 256 256 ./logo_source.png --out "$DEST/icon_256x256.png"
sips -z 512 512 ./logo_source.png --out "$DEST/icon_256x256@2x.png"
sips -z 512 512 ./logo_source.png --out "$DEST/icon_512x512.png"
sips -z 1024 1024 ./logo_source.png --out "$DEST/icon_512x512@2x.png"

# Удаляем временный файл
rm ./logo_source.png

echo "Resizing complete!"
