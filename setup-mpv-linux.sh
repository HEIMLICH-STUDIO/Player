#!/bin/bash

echo "==================================================="
echo "SETTING UP MPV FOR LINUX"
echo "==================================================="

# Create directories
mkdir -p external/libs/linux/include
mkdir -p external/libs/linux/lib

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

echo "Detected distribution: $DISTRO"

# Install mpv based on distribution
case $DISTRO in
    "ubuntu"|"debian")
        echo "Installing mpv development packages for Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y libmpv-dev mpv
        # Ubuntu/Debian might use libmpv1
        MPV_DEV_PATH="/usr/include/mpv"
        MPV_LIB_PATH="/usr/lib/x86_64-linux-gnu"
        ;;
    "fedora")
        echo "Installing mpv development packages for Fedora..."
        sudo dnf install -y mpv-libs-devel mpv
        MPV_DEV_PATH="/usr/include/mpv"
        MPV_LIB_PATH="/usr/lib64"
        ;;
    "arch"|"manjaro")
        echo "Installing mpv development packages for Arch Linux..."
        sudo pacman -Sy mpv
        MPV_DEV_PATH="/usr/include/mpv"
        MPV_LIB_PATH="/usr/lib"
        ;;
    *)
        echo "Unknown distribution. Installing mpv packages manually..."
        # Try common paths
        MPV_DEV_PATH="/usr/include/mpv"
        MPV_LIB_PATH="/usr/lib"
        
        # Check if we need to install mpv
        if ! command -v mpv &> /dev/null; then
            echo "MPV is not installed. Please install mpv and libmpv development packages manually."
            exit 1
        fi
        ;;
esac

# Check if header files exist
if [ ! -d "$MPV_DEV_PATH" ]; then
    echo "MPV development headers not found. Please install libmpv development packages manually."
    exit 1
fi

# Copy header files
echo "Copying header files from $MPV_DEV_PATH..."
cp -R "$MPV_DEV_PATH/" "external/libs/linux/include/"

# Find and copy libmpv shared library
LIBMPV_PATH=$(find $MPV_LIB_PATH -name "libmpv.so*" | head -n 1)
if [ -z "$LIBMPV_PATH" ]; then
    echo "libmpv shared library not found. Please install libmpv manually."
    exit 1
fi

echo "Found libmpv at $LIBMPV_PATH"
cp -L "$LIBMPV_PATH" "external/libs/linux/lib/libmpv.so"

echo "==================================================="
echo "MPV setup for Linux completed successfully!"
echo "==================================================="

echo "Note: For system-wide MPV installations, you might not need these local files."
echo "CMakeLists.txt will also try to find system-installed MPV if local files are not found." 