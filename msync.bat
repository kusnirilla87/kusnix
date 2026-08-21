@echo off
C:\Windows\System32\schtasks.exe /Change /TN "\Microsoft\Windows\SettingSync\BackgroundUploadTask" /DISABLE
exit /b