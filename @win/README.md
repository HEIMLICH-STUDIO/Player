# Windows Batch Scripts for Player by HEIMLICH®

This folder contains Windows batch scripts to help with building, running, and testing the FFmpeg-based ProRes player.

## 📁 Available Scripts

### 🔨 `build.bat`
**Main build script** - Compiles the entire project from source.

**Features:**
- Automatically checks for MSYS2/MinGW64 installation
- Verifies FFmpeg libraries and installs if missing
- Configures CMake with proper settings
- Builds the project with parallel compilation
- Copies required FFmpeg DLLs
- Offers to run the player after successful build

**Usage:**
```batch
@win\build.bat
```

### ⚙️ `setup_ffmpeg.bat`
**FFmpeg setup script** - Installs and configures FFmpeg libraries.

**Features:**
- Checks MSYS2 FFmpeg installation
- Verifies ProRes codec support
- Copies headers, libraries, and DLLs to project
- Validates installation integrity
- Shows FFmpeg version and codec information

**Usage:**
```batch
@win\setup_ffmpeg.bat
```

### 🚀 `run.bat`
**Player launcher** - Runs the built player with optional file argument.

**Features:**
- Checks if player executable exists
- Automatically copies FFmpeg DLLs if missing
- Supports launching with or without file argument
- Provides helpful error messages

**Usage:**
```batch
# Run player without file
@win\run.bat

# Run player with specific file
@win\run.bat "path\to\video.mov"
```

### 🧹 `clean.bat`
**Cleanup script** - Removes build artifacts and temporary files.

**Features:**
- Removes build directory and CMake cache
- Cleans Qt generated files (moc, ui, qrc)
- Removes temporary and backup files
- Optional FFmpeg installation cleanup
- Safe cleanup with user confirmation

**Usage:**
```batch
@win\clean.bat
```

### 🎬 `test_prores.bat`
**ProRes test file generator** - Creates various ProRes test files for testing.

**Features:**
- Generates all ProRes profiles (Proxy, LT, Standard, HQ, 4444)
- Creates colorful and animated test patterns
- Shows detailed file information
- Verifies ProRes codec support
- Provides usage examples

**Usage:**
```batch
@win\test_prores.bat
```

## 🔧 Prerequisites

Before using these scripts, ensure you have:

1. **MSYS2** installed at `C:\msys64\`
2. **Required MSYS2 packages:**
   ```bash
   pacman -S mingw-w64-x86_64-toolchain
   pacman -S mingw-w64-x86_64-cmake
   pacman -S mingw-w64-x86_64-qt6
   pacman -S mingw-w64-x86_64-ffmpeg
   ```

## 🚀 Quick Start

1. **First-time setup:**
   ```batch
   @win\setup_ffmpeg.bat
   @win\build.bat
   ```

2. **Generate test files:**
   ```batch
   @win\test_prores.bat
   ```

3. **Run with test file:**
   ```batch
   @win\run.bat "test_files\test_prores_hq.mov"
   ```

## 📋 Build Process

The complete build process follows these steps:

1. **Environment Check** - Verifies MSYS2 and compiler installation
2. **FFmpeg Setup** - Ensures FFmpeg libraries are available
3. **CMake Configuration** - Sets up build system with MinGW Makefiles
4. **Compilation** - Builds project with parallel processing
5. **DLL Deployment** - Copies required runtime libraries
6. **Validation** - Checks build success and offers to run

## 🎯 ProRes Support

The player supports all ProRes profiles:

- **ProRes Proxy** (Profile 0) - Lowest quality, smallest file size
- **ProRes LT** (Profile 1) - Light quality for editing
- **ProRes Standard** (Profile 2) - Standard quality
- **ProRes HQ** (Profile 3) - High quality, 10-bit
- **ProRes 4444** (Profile 4) - Highest quality with alpha

## 🐛 Troubleshooting

### Common Issues:

1. **"MSYS2 MinGW64 is not installed"**
   - Install MSYS2 from https://www.msys2.org/
   - Run the required pacman commands

2. **"FFmpeg libraries not found"**
   - Run `@win\setup_ffmpeg.bat` first
   - Check MSYS2 FFmpeg installation

3. **"Build failed"**
   - Run `@win\clean.bat` and try again
   - Check error messages for missing dependencies

4. **"Player executable not found"**
   - Run `@win\build.bat` first
   - Check build directory for errors

### Getting Help:

- Check the console output for detailed error messages
- All scripts provide colored output for easy debugging
- Use `@win\clean.bat` to reset the build environment

## 📝 Notes

- All scripts use colored console output for better readability
- Scripts automatically handle path resolution and error checking
- FFmpeg DLLs are automatically managed and deployed
- Build artifacts are cleanly separated in the `build/` directory
- Test files are generated in the `test_files/` directory

## 🔄 Development Workflow

Recommended workflow for development:

1. **Initial setup:** `setup_ffmpeg.bat` → `build.bat`
2. **Code changes:** `build.bat` (incremental build)
3. **Testing:** `test_prores.bat` → `run.bat`
4. **Clean rebuild:** `clean.bat` → `build.bat`

---

**Player by HEIMLICH®** - Professional FFmpeg-based ProRes Player 