#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Macroform Inbox"
EXEC_NAME="MacroformInbox"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"

cd "$ROOT"
swift build -c release

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$ROOT/Sources/App/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/.build/release/$EXEC_NAME" "$CONTENTS/MacOS/$EXEC_NAME"
chmod +x "$CONTENTS/MacOS/$EXEC_NAME"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "Packed: $APP"
