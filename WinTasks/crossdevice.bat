@echo off
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume" /v value /t REG_DWORD /d 1 /f >nul
exit