#!/bin/bash
set -e

echo "Building Domates..."
swift build -c release 2>&1

APP="Domates.app"
CONTENTS="$APP/Contents"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp .build/release/Domates "$CONTENTS/MacOS/"
cp Info.plist "$CONTENTS/"

echo ""
echo "✅ Built: $APP"
echo "Run with: open Domates.app"
echo "Or move to /Applications: mv Domates.app /Applications/"
