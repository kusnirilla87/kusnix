@echo off
del /q /f /s "%appdata%\Microsoft\windows\recent\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\automaticdestinations\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\customdestinations\*" >nul 2>&1
exit 