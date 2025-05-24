#!/bin/bash

echo "==================================================="
echo "SETTING UP MPV FOR macOS"
echo "==================================================="

# Navigate to project root
cd ../..

# Create directories
mkdir -p external/libs/macos/include
mkdir -p external/libs/macos/lib

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    echo "Visit https://brew.sh for installation instructions."
    exit 1
fi

# Install mpv using Homebrew
echo "Installing mpv using Homebrew..."
brew install mpv

# Get mpv library path
MPV_LIB_PATH=$(brew --prefix mpv)
echo "MPV library path: $MPV_LIB_PATH"

if [ ! -d "$MPV_LIB_PATH" ]; then
    echo "MPV installation not found. Please install mpv manually."
    exit 1
fi

# Copy header files
echo "Copying header files..."
cp -R "$MPV_LIB_PATH/include/mpv/" "external/libs/macos/include/"

# Copy library files
echo "Copying library files..."
cp -R "$MPV_LIB_PATH/lib/libmpv"*.dylib "external/libs/macos/lib/"

# Create Info.plist directory
mkdir -p macos
if [ ! -f "macos/Info.plist" ]; then
    cat > macos/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Player by HEIMLICH</string>
    <key>CFBundleExecutable</key>
    <string>Player-by-HEIMLICH</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.heimlich.player</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Player by HEIMLICH</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
    echo "Created Info.plist for macOS bundle"
fi

echo "==================================================="
echo "MPV setup for macOS completed successfully!"
echo "==================================================="

cd batch/macos 