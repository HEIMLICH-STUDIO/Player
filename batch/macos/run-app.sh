#!/bin/bash

echo "Checking if executable exists..."
if [ ! -f "../../build/Player-by-HEIMLICH" ]; then
    echo "Player-by-HEIMLICH not found in build directory!"
    exit 1
fi

echo "Making sure the MPV library is available..."
if [ -f "../../external/libs/macos/lib/libmpv.dylib" ]; then
    if [ ! -f "../../build/libmpv.dylib" ]; then
        echo "Copying libmpv.dylib to build directory..."
        cp "../../external/libs/macos/lib/libmpv"*.dylib "../../build/"
    else
        echo "libmpv.dylib already exists in build directory."
    fi
else
    echo "INFO: Using system MPV library (installed via Homebrew)"
fi

echo "Starting Player by HEIMLICH®..."
cd ../../build
./Player-by-HEIMLICH &
cd ../batch/macos

echo "Done!" 