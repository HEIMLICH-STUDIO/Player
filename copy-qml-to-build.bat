@echo off
echo Copying QML files to build directory...

:: Create qml directory in build if it doesn't exist
if not exist "build\qml" mkdir "build\qml"

:: Copy all QML files
xcopy /Y "qml\*.qml" "build\qml\"
xcopy /Y "qml\qmldir" "build\qml\"

echo QML files copied successfully! 