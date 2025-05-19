# Manual MPV Installation Guide

If the automated scripts (`download_mpv.bat` or `download_mpv.ps1`) don't work for you, follow these steps to manually install MPV libraries:

## Step 1: Download MPV Development Files

### Option 1: From GitHub (Recommended)
1. Go to the [MPV Releases page on GitHub](https://github.com/mpv-player/mpv/releases)
2. Download the latest `mpv-dev-x86_64-*.7z` file (e.g., `mpv-dev-x86_64-20230806-git-7d9e628.7z`)

### Option 2: From SourceForge
1. Go to the [MPV Windows builds page](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)
2. Download the latest `mpv-dev-x86_64-*.7z` file

## Step 2: Create Directory Structure

Create the following directories in your project folder:
```
external/
  mpv/
    include/
    lib/
    bin/
```

You can create them with this PowerShell command:
```powershell
New-Item -Path "external\mpv\include", "external\mpv\lib", "external\mpv\bin" -ItemType Directory -Force
```

Or with these CMD commands:
```cmd
mkdir external\mpv\include
mkdir external\mpv\lib
mkdir external\mpv\bin
```

## Step 3: Extract and Copy Files

1. Extract the downloaded `.7z` file using [7-Zip](https://www.7-zip.org/)
2. Copy the extracted files to the following locations:
   - `include/mpv/*.h` → `external/mpv/include/`
   - `*.dll.a` → `external/mpv/lib/`
   - `*.dll` → `external/mpv/bin/`

You can use these PowerShell commands:
```powershell
# Extract to temporary folder (replace with your downloaded filename)
& "C:\Program Files\7-Zip\7z.exe" x "mpv-dev-x86_64-20230806-git-7d9e628.7z" -otmp -y

# Copy files
Copy-Item -Path "tmp\include\mpv\*.h" -Destination "external\mpv\include\" -Force
Copy-Item -Path "tmp\*.dll.a" -Destination "external\mpv\lib\" -Force
Copy-Item -Path "tmp\*.dll" -Destination "external\mpv\bin\" -Force

# Clean up
Remove-Item -Path "tmp" -Recurse -Force
```

## Step 4: Verify Installation

After copying the files, verify the installation by checking if these key files exist:
- `external/mpv/include/client.h` (header file)
- `external/mpv/bin/libmpv-2.dll` (runtime DLL)

If these files are present, the installation was successful.

## Step 5: Build HYPER-PLAYER

Run `build.bat` to build the application with MPV support.

## Troubleshooting

If you encounter problems:

1. **MPV not found during build**: Check that the files are in the correct directories
2. **Build errors**: Make sure you have installed all prerequisites (Qt 6, CMake, C++ compiler)
3. **Runtime errors**: Make sure the `libmpv-2.dll` is either in the application directory or in your system PATH

## Manually Downloading Alternative MPV Versions

If you need a different version of MPV:

1. Visit [MPV GitHub releases](https://github.com/mpv-player/mpv/releases)
2. Find a compatible Windows build or compile from source
3. Place the files in the same directory structure as mentioned above 