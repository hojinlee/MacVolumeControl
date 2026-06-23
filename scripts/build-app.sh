#!/bin/zsh

set -euo pipefail

ROOT_DIR=${0:A:h}/..
cd "$ROOT_DIR"

APP_NAME="MacVolumeControl"
OUTPUT_DIR="$ROOT_DIR/build/$APP_NAME.app"
EXECUTABLE_PATH="$ROOT_DIR/.build/release/$APP_NAME"
APP_ICON_SOURCE="$ROOT_DIR/Assets/AppIcon-1024.png"
CACHE_HOME="$ROOT_DIR/.localhome"
MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache"
CLANG_CACHE_PATH="$ROOT_DIR/.build/ClangModuleCache"

mkdir -p \
  "$CACHE_HOME/.cache/clang/ModuleCache" \
  "$CACHE_HOME/Library/Caches/org.swift.swiftpm" \
  "$CACHE_HOME/Library/org.swift.swiftpm/configuration" \
  "$CACHE_HOME/Library/org.swift.swiftpm/security" \
  "$MODULE_CACHE_PATH" \
  "$CLANG_CACHE_PATH"

HOME="$CACHE_HOME" \
SWIFT_MODULECACHE_PATH="$MODULE_CACHE_PATH" \
CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_PATH" \
swift build -c release --disable-sandbox

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Contents/MacOS" "$OUTPUT_DIR/Contents/Resources"

cp "$EXECUTABLE_PATH" "$OUTPUT_DIR/Contents/MacOS/$APP_NAME"

ICON_PNG_DIR="$ROOT_DIR/build/AppIcon.pngset"
rm -rf "$ICON_PNG_DIR"
mkdir -p "$ICON_PNG_DIR"

sips -z 16 16 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_16.png" >/dev/null
sips -z 32 32 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_32.png" >/dev/null
sips -z 64 64 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_64.png" >/dev/null
sips -z 128 128 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_128.png" >/dev/null
sips -z 256 256 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_256.png" >/dev/null
sips -z 512 512 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_512.png" >/dev/null
sips -z 1024 1024 "$APP_ICON_SOURCE" --out "$ICON_PNG_DIR/icon_1024.png" >/dev/null

ROOT_DIR_ENV="$ROOT_DIR" OUTPUT_DIR_ENV="$OUTPUT_DIR" python3 - <<'PY'
import os
from pathlib import Path
import struct

root = Path(os.environ["ROOT_DIR_ENV"])
png_dir = root / "build" / "AppIcon.pngset"
out_path = Path(os.environ["OUTPUT_DIR_ENV"]) / "Contents" / "Resources" / "AppIcon.icns"

entries = [
    ("icp4", png_dir / "icon_16.png"),
    ("icp5", png_dir / "icon_32.png"),
    ("icp6", png_dir / "icon_64.png"),
    ("ic07", png_dir / "icon_128.png"),
    ("ic08", png_dir / "icon_256.png"),
    ("ic09", png_dir / "icon_512.png"),
    ("ic10", png_dir / "icon_1024.png"),
]

chunks = []
for icon_type, path in entries:
    data = path.read_bytes()
    chunks.append(icon_type.encode("ascii") + struct.pack(">I", len(data) + 8) + data)

body = b"".join(chunks)
out_path.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
PY

cat > "$OUTPUT_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>MacVolumeControl</string>
    <key>CFBundleExecutable</key>
    <string>MacVolumeControl</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.hojinlee.MacVolumeControl</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacVolumeControl</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built app bundle at $OUTPUT_DIR"
