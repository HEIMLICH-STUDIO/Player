# MPV Setup Guide for HYPER-PLAYER

## Current Status

You have:
- The MPV source code in `external/mpv/`
- The header files copied to `external/mpv-dev/include/`
- The CMakeLists.txt updated to use `external/mpv-dev/` instead of `external/mpv/`

## What's Missing

You need to download and extract:
- MPV development files (DLLs and library files)

## Complete the Setup

1. Download the MPV development package:
   - Go to: https://github.com/mpv-player/mpv/releases/tag/v0.40.0
   - Download: `mpv-dev-x86_64-20240325-git-82d82d0.7z`

2. Extract the 7z archive and copy:
   - All `.dll.a` files → `external/mpv-dev/lib/`
   - All `.dll` files → `external/mpv-dev/bin/`

3. Build your project:
   ```
   mkdir build
   cd build
   cmake ..
   cmake --build .
   ```

## Troubleshooting

If the build fails to find MPV:
- Make sure `libmpv-2.dll` is in `external/mpv-dev/bin/`
- Make sure `mpv.dll.a` is in `external/mpv-dev/lib/`
- Check that both `client.h` and other headers are in `external/mpv-dev/include/`

## Manual Download Instructions

If GitHub download doesn't work, try these alternative MPV download locations:

1. SourceForge:
   - https://sourceforge.net/projects/mpv-player-windows/files/libmpv/

2. MPV Windows Builds:
   - https://mpv.io/installation/

Once downloaded, extract the files as described above. 