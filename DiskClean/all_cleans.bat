@echo off
DISM.exe /Online /Set-ReservedStorageState /State:Disabled
del /f /q /s "%systemroot%\SoftwareDistribution\Download\*.*" 2>nul
echo Очищення кешу Google Chrome...
del /q /f /s "%localappdata%\Google\Chrome\User Data\Default\Cache\*.*" 2>nul

echo Очищення кешу Microsoft Edge...
del /q /f /s "%localappdata%\Microsoft\Edge\User Data\Default\Cache\*.*" 2>nul

echo Очищення кешу Opera...
del /q /f /s "%localappdata%\Opera Software\Opera Stable\Cache\*.*" 2>nul

echo Очищення кешу Discord...
del /q /f /s "%appdata%\discord\Cache\*.*" 2>nul
del /q /f /s "%appdata%\discord\Code Cache\*.*" 2>nul

echo Очищення офлайн-кешу Spotify...
del /q /f /s "%localappdata%\Spotify\Storage\*.*" 2>nul

echo Очищення медіа-кешу Adobe...
del /q /f /s "%appdata%\Adobe\Common\Media Cache Files\*.*" 2>nul

echo Очищення кешу вбудованого браузера Steam...
del /q /f /s "%localappdata%\Steam\htmlcache\*.*" 2>nul

echo Очищення веб-кешу Epic Games...
del /q /f /s "%localappdata%\EpicGamesLauncher\Saved\webcache\*.*" 2>nul

del /q /f /s "C:\Program Files\WindowsApps\Deleted" 2>nul
del /q /f /s "C:\Program Files\WindowsApps\DeletedAllUserPackages" 2>nul

del /q /f /s "%appdata%\Microsoft\windows\recent\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\automaticdestinations\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\customdestinations\*" >nul 2>&1
exit