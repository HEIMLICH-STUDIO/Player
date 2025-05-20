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

:: Create and copy ui subdirectory
if not exist "build\qml\ui" mkdir "build\qml\ui"
xcopy /Y /S "qml\ui\*" "build\qml\ui\"

:: Create and copy widgets subdirectory
if not exist "build\qml\widgets" mkdir "build\qml\widgets"
xcopy /Y /S "qml\widgets\*" "build\qml\widgets\"

:: Create and copy utils subdirectory
if not exist "build\qml\utils" mkdir "build\qml\utils"
xcopy /Y /S "qml\utils\*" "build\qml\utils\"

:: Also create and copy other directories if they exist
if exist "qml\controls" (
    if not exist "build\qml\controls" mkdir "build\qml\controls"
    xcopy /Y /S "qml\controls\*" "build\qml\controls\"
)

if exist "qml\panels" (
    if not exist "build\qml\panels" mkdir "build\qml\panels"
    xcopy /Y /S "qml\panels\*" "build\qml\panels\"
)

if exist "qml\popups" (
    if not exist "build\qml\popups" mkdir "build\qml\popups"
    xcopy /Y /S "qml\popups\*" "build\qml\popups\"
)

:: Create and copy assets directory (for icons)
echo [INFO] Copying assets...
if not exist "build\assets" mkdir "build\assets"
if not exist "build\assets\icons" mkdir "build\assets\icons"
xcopy /Y /S "assets\icons\*" "build\assets\icons\"

echo [INFO] QML files and assets copied successfully! 