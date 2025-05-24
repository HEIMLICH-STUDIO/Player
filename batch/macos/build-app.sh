#!/bin/bash

echo "==================================================="
echo "Building Player by HEIMLICH for macOS"
echo "==================================================="

# Navigate to project root
cd ../..

# Extract version from CMakeLists.txt
echo "[INFO] Extracting version information from CMakeLists.txt..."
MAJOR=$(grep "set(PROJECT_VERSION_MAJOR" CMakeLists.txt | sed 's/.*set(PROJECT_VERSION_MAJOR \([0-9]*\)).*/\1/')
MINOR=$(grep "set(PROJECT_VERSION_MINOR" CMakeLists.txt | sed 's/.*set(PROJECT_VERSION_MINOR \([0-9]*\)).*/\1/')
PATCH=$(grep "set(PROJECT_VERSION_PATCH" CMakeLists.txt | sed 's/.*set(PROJECT_VERSION_PATCH \([0-9]*\)).*/\1/')

CURRENT_VERSION="$MAJOR.$MINOR.$PATCH"
echo "[INFO] Current project version: $CURRENT_VERSION"
echo

# Kill any running processes
echo "[STEP 1] Terminating any running Player processes..."
killall Player-by-HEIMLICH 2>/dev/null || true
sleep 2
echo "[SUCCESS] All processes terminated!"
echo

# Clean up previous build files
echo "[STEP 2] Cleaning up previous build files..."
if [ -d "build" ]; then
    rm -rf build
    sleep 1
fi
mkdir build

# Check for Qt installation
echo "[STEP 3] Checking Qt installation..."
if ! command -v qmake &> /dev/null; then
    echo "[ERROR] Qt not found. Please install Qt for macOS."
    echo "You can install it via:"
    echo "1. Download from https://www.qt.io/download"
    echo "2. Or install via Homebrew: brew install qt"
    exit 1
fi

QT_PATH=$(qmake -query QT_INSTALL_PREFIX)
echo "[INFO] Qt found at: $QT_PATH"

# Run CMake
echo "[STEP 4] Running CMake..."
cd build
cmake -DCMAKE_PREFIX_PATH="$QT_PATH" -DCMAKE_BUILD_TYPE=Release ..

if [ $? -ne 0 ]; then
    echo "[ERROR] CMake configuration failed!"
    cd ../batch/macos
    exit 1
fi

# Build the application
echo "[STEP 5] Building the application..."
make -j$(sysctl -n hw.ncpu)

BUILD_STATUS=$?
cd ..

if [ "$BUILD_STATUS" = "0" ]; then
    echo "[STEP 6] Build completed successfully!"
    
    # Copy MPV library if needed
    if [ -f "external/libs/macos/lib/libmpv.dylib" ]; then
        echo "[INFO] Copying MPV library..."
        cp external/libs/macos/lib/libmpv*.dylib build/
    fi
    
    # Copy QML files
    echo "[INFO] Copying QML files..."
    if [ ! -d "build/qml" ]; then
        mkdir build/qml
    fi
    cp -r qml/* build/qml/
    
    # Copy assets
    echo "[INFO] Copying assets..."
    if [ ! -d "build/assets" ]; then
        mkdir build/assets
    fi
    cp -r assets/* build/assets/
    
    echo
    echo "==================================================="
    echo "Build completed successfully!"
    echo "Executable location: build/Player-by-HEIMLICH"
    echo "==================================================="
    
else
    echo "[ERROR] Build failed!"
fi

cd batch/macos
echo "Build script completed from batch/macos directory!" 