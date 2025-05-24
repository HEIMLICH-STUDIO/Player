#!/bin/bash

echo "Checking if executable exists..."
if [ ! -f "../../build/Player-by-HEIMLICH" ]; then
    echo "Player-by-HEIMLICH not found in build directory!"
    exit 1
fi

echo "Making sure the MPV library is available..."
if [ -f "../../external/libs/linux/lib/libmpv.so" ]; then
    if [ ! -f "../../build/libmpv.so" ]; then
        echo "Copying libmpv.so to build directory..."
        cp "../../external/libs/linux/lib/libmpv.so" "../../build/"
    else
        echo "libmpv.so already exists in build directory."
    fi
else
    echo "INFO: Using system MPV library (installed via package manager)"
fi

echo "Starting Player by HEIMLICH®..."
cd ../../build
./Player-by-HEIMLICH &
cd ../batch/linux

echo "Done!" 