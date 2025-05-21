@echo off
echo [INFO] Copying QML files...

:: Create qml directory in build if it doesn't exist
if not exist "build\qml" mkdir "build\qml"

:: Copy main qmldir file
xcopy /Y "qml\qmldir" "build\qml\"
xcopy /Y "qml\*.qml" "build\qml\"

:: Create and copy core subdirectory
if not exist "build\qml\core" mkdir "build\qml\core"
xcopy /Y /S "qml\core\*" "build\qml\core\"
echo [INFO] Core files copied.

:: Create and copy ui subdirectory
if not exist "build\qml\ui" mkdir "build\qml\ui"
xcopy /Y /S "qml\ui\*" "build\qml\ui\"
echo [INFO] UI files copied.

:: Create and copy widgets subdirectory
if not exist "build\qml\widgets" mkdir "build\qml\widgets"
xcopy /Y /S "qml\widgets\*" "build\qml\widgets\"
echo [INFO] Widget files copied.

:: Create and copy utils subdirectory
if not exist "build\qml\utils" mkdir "build\qml\utils"
xcopy /Y /S "qml\utils\*" "build\qml\utils\"
echo [INFO] Utils files copied.

:: Control directory has been removed - widgets are now used instead
:: echo [INFO] Copying controls directory...
:: if not exist "build\qml\controls" mkdir "build\qml\controls"
:: xcopy /Y /S "qml\controls\*" "build\qml\controls\"

:: Create and copy panels subdirectory
if not exist "build\qml\panels" mkdir "build\qml\panels"
xcopy /Y /S "qml\panels\*" "build\qml\panels\"
echo [INFO] Panels files copied.

:: Create and copy popups subdirectory
if not exist "build\qml\popups" mkdir "build\qml\popups"
xcopy /Y /S "qml\popups\*" "build\qml\popups\"
echo [INFO] Popups files copied.

:: Create and copy assets directory (for icons)
echo [INFO] Copying assets...
if not exist "build\assets" mkdir "build\assets"
if not exist "build\assets\icons" mkdir "build\assets\icons"
xcopy /Y /S "assets\icons\*" "build\assets\icons\"

echo [INFO] All QML files and assets copied successfully!
echo [INFO] Cleaning up temporary build directory 