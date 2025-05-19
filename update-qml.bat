@echo off
echo Copying QML files to build directory...
xcopy /Y /S qml\*.* build\qml\
echo Done!
pause 