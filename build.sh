#!/bin/bash

echo "Building Weight CLI and Desktop versions..."

# Build CLI
echo "Building CLI..."
dart compile exe bin/weight_cli.dart -o weight

# Build Desktop Apps
echo "Building Desktop Apps..."
cd desktop

# Get dependencies
flutter pub get

# Build for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building macOS app..."
    flutter build macos --release
    echo "macOS app built: desktop/build/macos/Build/Products/Release/weight_desktop.app"
fi

# Build for Windows (if on Windows or with cross-compilation)
if command -v flutter &> /dev/null; then
    echo "Building Windows app..."
    flutter build windows --release 2>/dev/null || echo "Windows build skipped (not available on this platform)"
fi

# Build for Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Building Linux app..."
    flutter build linux --release
    echo "Linux app built: desktop/build/linux/x64/release/bundle/"
fi

cd ..

echo "Build complete!"
echo "CLI binary: ./weight"
echo "Desktop apps in: ./desktop/build/"
