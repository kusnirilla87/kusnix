 @echo off
setlocal EnableExtensions
set "SCRIPT=%~dp0netadapterpreset.ps1"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
chcp 65001 > nul
title KusniX
mode con: cols=80 lines=32
color 0A
setlocal enabledelayedexpansion

set "regKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
set "valName=HideFileExt"

for /f "tokens=3" %%A in ('reg query "%regKey%" /v %valName% 2^>nul ^| findstr /i "%valName%"') do (
    set "curVal=%%A"
)

if "!curVal!"=="0x1" (
    reg add "%regKey%" /v %valName% /t REG_DWORD /d 0 /f
    taskkill /f /im explorer.exe
    start explorer.exe
) else (
    echo OK
)

endlocal
for /F "tokens=1 delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "C_BORDER=%ESC%[38;2;51;65;85m"        
set "C_TITLE=%ESC%[38;2;56;189;248m%ESC%[1m"   
set "C_NUM=%ESC%[38;2;251;191;36m%ESC%[1m"    
set "C_TEXT=%ESC%[38;2;226;232;240m"      
set "C_MUTED=%ESC%[38;2;100;116;139m"   
set "C_ACCENT=%ESC%[38;2;244;63;94m%ESC%[1m"   
set "C_GREEN=%ESC%[38;2;74;222;128m%ESC%[1m"   
set "C_PROMPT=%ESC%[38;2;168;85;247m%ESC%[1m"  
set "RESET=%ESC%[0m"


if "%1"=="admin" goto menu

NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo starting with admin...
    powershell -Command "Start-Process '%~f0' -ArgumentList 'admin' -Verb RunAs"
    exit /b
)

:menu
color 0a
cls
echo ================================================================================
echo.
echo			██╗  ██╗██╗   ██╗███████╗███╗   ██╗██╗    ██╗  ██╗
echo			██║ ██╔╝██║   ██║██╔════╝████╗  ██║██║    ╚██╗██╔╝
echo			█████╔╝ ██║   ██║███████╗██╔██╗ ██║██║     ╚███╔╝ 
echo			██╔═██╗ ██║   ██║╚════██║██║╚██╗██║██║     ██╔██╗ 
echo			██║  ██╗╚██████╔╝███████║██║ ╚████║██║    ██╔╝ ██╗
echo			╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝    ╚═╝  ╚═╝
echo             		      Tweaker[v1.4]
echo ================================================================================
echo.
echo.
echo			[1] Налаштування Завдань Windows
echo.
echo		        [2] Налаштуваня MMCSS твіків
echo.
echo			[3] Очищення диску(кеш, сміття, залишки...)		        
echo.
echo			[4] Налаштування мережевого адаптера(Ethernet)
echo.
echo			[5] Налаштування переривань(Interrupts)
echo.
echo			[6] Ввімкнути "Блокування маршрутизації переривань"
echo.		
echo.
echo ================================================================================   		
echo.
echo			[R] Сторінка виправлень (Увімкнути...)
echo.
echo ================================================================================
set /p choice="Обери варіант (1-6, R): "

if "%choice%"=="1" goto wintasks
if "%choice%"=="2" goto MMCSStweaks
if "%choice%"=="3" goto diskclean
if "%choice%"=="4" goto netadapter
if "%choice%"=="5" goto interrupts
if "%choice%"=="6" goto lockinro

if /i "%choice%"=="r" goto revert

echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto menu

:wintasks
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo                Завантаження сторінки: Завдання Windows
echo             ====================================================
echo                [████████████████████████████████████████] 100%%
echo             ====================================================
timeout 1 >nul
cls
chcp 65001 > nul
cls
cls
echo.
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% WINDOWS TASKS %C_MUTED%│ Оптимізація планувальника завдань%C_BORDER%                   ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Завдання Windows Insider    %C_NUM%[9]%C_TEXT%  Синхронізація Microsoft  %C_BORDER%    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Завдання для аналізу        %C_NUM%[10]%C_TEXT% Завдання очищення       %C_BORDER%     ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Завдання діагностики        %C_NUM%[11]%C_TEXT% Завдання Microsoft Store%C_BORDER%     ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Автовизначення проксі       %C_NUM%[12]%C_TEXT% Завдання Xbox Live      %C_BORDER%     ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Встановлення/видалення мов  %C_NUM%[13]%C_TEXT% Оновлення політики     %C_BORDER%      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[6]%C_TEXT%  Автоперевірка продуктивн.   %C_NUM%[14]%C_TEXT% Завдання для HDD        %C_BORDER%     ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[7]%C_TEXT%  Карти та Геолокація         %C_NUM%[15]%C_TEXT% Сповіщення EOL          %C_BORDER%     ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[8]%C_TEXT%  Віддалене керування                                          %C_BORDER% ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Головне Меню            %C_GREEN%[R]%C_MUTED% Сторінка виправлень (Увімкнути...)%C_BORDER% ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[A]  ЗАСТОСУВАТИ УСІ ТВІКИ ВІДРАЗУ%C_BORDER%                               %C_BORDER%  ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Обери варіант %C_MUTED%(1-15, M, R, A)%C_TEXT%: %RESET%"
 
if "%choice%"=="1" goto twinsider
if "%choice%"=="2" goto tanalisys
if "%choice%"=="3" goto tdiagn
if "%choice%"=="4" goto tproxy
if "%choice%"=="5" goto tlang
if "%choice%"=="6" goto tperf
if "%choice%"=="7" goto tmaps
if "%choice%"=="8" goto tanyd
if "%choice%"=="9" goto tmsync
if "%choice%"=="10" goto tclean
if "%choice%"=="11" goto tmstore
if "%choice%"=="12" goto txbox
if "%choice%"=="13" goto tpolicy
if "%choice%"=="14" goto thdd
if "%choice%"=="15" goto teol

if /i "%choice%"=="a" goto all_tweaks
if /i "%choice%"=="r" goto revert
if /i "%choice%"=="m" goto menu
echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto wintasks

:twinsider
cls
echo [!] Застосування Твіку 1...
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /disable
echo [+] Твік 1 успішно застосовано!
pause
goto wintasks

:tanalisys
cls
echo [!] Застосування Твіку 2...
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /disable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /disable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /disable
echo [+] Твік 2 успішно застосовано!
pause
goto wintasks

:tdiagn
cls
echo [!] Застосування Твіку 3...
schtasks /change /tn "Microsoft\Windows\Chkdsk\ProactiveScan" /disable
schtasks /change /tn "Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /disable
schtasks /change /tn "Microsoft\Windows\Diagnosis\Scheduled" /disable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /disable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\Diagnostics" /disable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\StorageSense" /disable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /disable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /disable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /change /tn "Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /disable
schtasks /change /tn "Microsoft\Windows\Server Manager\ServerManager" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierdaily" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierinstall" /disable
schtasks /change /tn "Microsoft\Windows\WindowsColorSystem\Calibration Loader" /disable
echo [+] Твік 3 успішно застосовано!
pause
goto wintasks

:tproxy
cls
echo [!] Застосування Твіку 4...
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /disable
echo [+] Твік 4 успішно застосовано!
pause
goto wintasks

:tlang
cls
echo [!] Застосування Твіку 5...
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /disable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /disable
echo [+] Твік 5 успішно застосовано!
pause
goto wintasks

:tperf
cls
echo [!] Застосування Твіку 6...
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /disable
echo [+] Твік 6 успішно застосовано!
pause
goto wintasks

:tmaps
cls
echo [!] Застосування Твіку 7...
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /disable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /disable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /disable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /disable
echo [+] Твік 7 успішно застосовано!
pause
goto wintasks

:tanyd
cls
echo [!] Застосування Твіку 8...
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /disable
echo [+] Твік 8 успішно застосовано!
pause
goto wintasks

:tmsync
cls
echo [!] Застосування Твіку 9...
start "" "C:\kusnix\pw.exe" "C:\kusnix\msync.bat"
schtasks /change /tn "Microsoft\Windows\SettingSync\NetworkStateChangeTask" /disable
echo [+] Твік 9 успішно застосовано!
pause
goto wintasks

:tclean
cls
echo [!] Застосування Твіку 10...
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /disable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /disable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /disable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /disable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /disable
echo [+] Твік 10 успішно застосовано!
pause
goto wintasks

:tmstore
cls
echo [!] Застосування Твіку 11...
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /disable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /disable
echo [+] Твік 11 успішно застосовано!
pause
goto wintasks

:txbox
cls
echo [!] Застосування Твіку 12...
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /disable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /disable
echo [+] Твік 12 успішно застосовано!
pause
goto wintasks

:tpolicy
cls
echo [!] Застосування Твіку 13...
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /disable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /disable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /disable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /disable
echo [+] Твік 13 успішно застосовано!
pause
goto wintasks

:thdd
cls
echo [!] Застосування Твіку 14...
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /disable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /disable
echo [+] Твік 14 успішно застосовано!
pause
goto wintasks

:teol
cls
echo [!] Застосування Твіку 15...
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /disable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /disable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /disable
echo [+] Твік 15 успішно застосовано!
pause
goto wintasks

:MMCSStweaks
cls
call C:\kusnix\checknic.bat
echo Якщо драйвер адаптера (WiFi/Ethernet) на NDIS:
echo.
echo    Застосуй Optimized-MMCSS-Settings.reg
echo.
echo    Перевір звук у грі.
echo.
echo        Немає затримок → ✅ завершено.
echo.
echo        Є затримки (W11 24H2+ + слабкий CPU + NVIDIA) → застосуй Audio-Stutters-Fix.reg.
echo.
echo Якщо драйвер на NetAdapterCx:
echo.
echo    Застосуй Disable-MMCSS.reg
echo.
echo    Перевір звук у грі.
echo.
echo        Немає переривань → ✅ завершено.
echo.
echo        Є переривання → застосуй Enable-MMCSS.reg + Optimized-MMCSS-Settings.reg.
echo.
echo        Якщо не допомогло → додай Audio-Stutters-Fix.reg.
echo.
echo.
echo [1] Optimized-MMCSS-Settings.reg
echo [2] Disable-MMCSS.reg
echo [3] Enable-MMCSS.reg
echo [4] Audio-Stutters-Fix.reg
echo [M] Головне меню
set /p choice=: 
if "%choice%"=="1" goto optmmcss
if "%choice%"=="2" goto dismmcss
if "%choice%"=="3" goto enmmcss
if "%choice%"=="4" goto audiofixmmcss
if "%choice%"=="m" goto menu
echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto MMCSStweaks
pause
goto menu

:optmmcss
cls
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d 0x00000000 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0x0000000a /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d 0xffffffff /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SchedulerPeriod" /t REG_DWORD /d 0x000f4240 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "IdleDetectionCycles" /t REG_DWORD /d 0x00000001 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SchedulerTimerResolution" /t REG_DWORD /d 0x00002710 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority" /t REG_DWORD /d 0x00000001 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority When Yielded" /t REG_DWORD /d 0x00000010 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d 0x00000001 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority When Yielded" /t REG_DWORD /d 0x00000010 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Priority" /t REG_DWORD /d 0x00000001 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Priority When Yielded" /t REG_DWORD /d 0x00000010 /f
pause
goto mmcsstweaks

:dismmcss
cls
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d 00000004 /f
pause
goto mmcsstweaks

:enmmcss
cls
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d 00000002 /f
pause
goto mmcsstweaks

:audiofixmmcss
cls
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SchedulerTimerResolution" /t REG_DWORD /d 0x00000001 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Scheduling Category" /t REG_SZ /d High /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority When Yielded" /t REG_DWORD /d 0x00000013 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d High /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority When Yielded" /t REG_DWORD /d 0x00000013 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Scheduling Category" /t REG_SZ /d High /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Priority When Yielded" /t REG_DWORD /d 0x00000013 /f
pause
goto mmcsstweaks


:diskclean
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo                Завантаження сторінки: Очищення диску
echo             ====================================================
echo                [████████████████████████████████████████] 100%%
echo             ====================================================
timeout 1 >nul
cls
chcp 65001 > nul
cls
echo.
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% DISK CLEANUP %C_MUTED%│ Система обслуговування диску%C_BORDER%                             ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_MUTED%[ ОСНОВНІ ОПЕРАЦІЇ ]%C_BORDER%                                                   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Вимкнути "Зарезервоване сховище оновлень"                        %C_BORDER% ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Очистити "Кеш Windows Update"                                     %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Додаткове розширене очищення кешу                                 %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Видалені UWP додатки (залишки)                                    %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Очищення слідів активності                                        %C_BORDER%║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED%  Головне Меню            %C_GREEN%[R]%C_MUTED%  Сторінка виправлень (Увімкнути...)%C_BORDER%   ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[A]  ОЧИСТИТИ ВСЕ МИТТЄВО%C_BORDER%                                              ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Обери варіант %C_MUTED%(1-5, M, R, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" goto restorage
if "%choice%"=="2" goto winupdatecache
if "%choice%"=="3" goto advanclean
if "%choice%"=="4" goto deluwp
if "%choice%"=="5" goto activityclean

if /i "%choice%"=="a" goto all_cleans
if /i "%choice%"=="r" goto revert
if /i "%choice%"=="m" goto menu
echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto diskclean

:restorage
cls
echo [!] Вимкнення "Зарезервоване сховище оновлень"...
DISM.exe /Online /Set-ReservedStorageState /State:Disabled
echo [+] "Зарезервоване сховище оновлень" успішно вимкнено!
pause
goto diskclean

:winupdatecache
cls
echo [!] Очищення кешу Windows Update...
del /f /q /s "%systemroot%\SoftwareDistribution\Download\*.*" 2>nul
echo [+] Кеш Windows Update успішно очищено!
pause
goto diskclean

:advanclean
cls
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

echo [+] Успішно очищено!
pause
goto diskclean

:deluwp
cls
echo [!] Очищення залишків видалених UWP додатків...
del /q /f /s "C:\Program Files\WindowsApps\Deleted" 2>nul
del /q /f /s "C:\Program Files\WindowsApps\DeletedAllUserPackages" 2>nul
echo [+] Залишки успішно видалено!
pause
goto diskclean

:activityclean
cls
echo [!] Очищення залишків активності...
del /q /f /s "%appdata%\Microsoft\windows\recent\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\automaticdestinations\*" >nul 2>&1
del /q /f /s "%appdata%\Microsoft\windows\recent\customdestinations\*" >nul 2>&1
pause
goto diskclean

:all_cleans
cls
echo [!] Запуск повного очищення...
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
echo [+] Успішно очищено!
pause
goto diskclean
:netadapter
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo            Завантаження сторінки: Налаштування мережевого адаптера
echo             ====================================================
echo                [████████████████████████████████████████] 100%%
echo             ====================================================
timeout 1 >nul
cls
if not exist "%SCRIPT%" (
  echo [ERROR] PowerShell script not found:
  echo         "%SCRIPT%"
  pause
  goto menu
)

fsutil dirty query %SystemDrive% >nul 2>&1
if not errorlevel 1 goto :RunScript

for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2^>nul') do set "LUA=%%A"
if not defined LUA set "LUA=0x1"
if /i "%LUA%"=="0x0" goto :ElevationImpossible
if "%LUA%"=="0" goto :ElevationImpossible

"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:ComSpec -Verb RunAs -ArgumentList '/c ""%~f0""' -WindowStyle Hidden" >nul 2>&1
exit /b 0

:ElevationImpossible
echo [ERROR] Admin rights required but UAC is disabled (EnableLUA=0).
echo         Run this .bat from an administrator account.
pause
exit /b 1

:RunScript
start "" "%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
goto menu

:interrupts
cls
for /L %%i in (1, 1, 27) do echo.
echo              ====================================================
echo                 Завантаження сторінки: Переривання
echo              ====================================================
echo                 [████████████████████████████████████████] 100%%
echo              ====================================================
timeout 1 >nul
cls
cls
echo.
echo  ======================================================================
echo   SYSTEM INTERRUPT OPTIMIZER ^| MSI ^& CPU MANAGEMENT
echo  ======================================================================
echo.
echo   [ОПИС МОДУЛЯ]
echo   Автоматичний комплекс для оптимізації обробки переривань:
echo    * Переведення пристроїв у режим MSI (Message Signaled Interrupts)
echo    * Балансування пріоритетів IRQ та прив'язка до потоків CPU
echo    * Фіксація та розподіл мережевих черг RSS (Receive Side Scaling)
echo.
echo  ----------------------------------------------------------------------
echo   [ОБЕРІТЬ ДІЮ]
echo.
echo    [1]  Запустити автоматичну конфігурацію
echo    [2]  Перейти до ручного налаштування
echo.
echo    [M]  Повернутися до головного меню
echo  ----------------------------------------------------------------------
echo.
set /p choice=: 
if "%choice%"=="1" goto autointerrupts
if "%choice%"=="2" start C:\kusnix\devicetweaker & goto interrupts
if "%choice%"=="m" goto menu
echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto interrupts

:autointerrupts
cls
echo =====================================================================
echo                   ЗАСТОСУВАННЯ АВТО-ОПТИМІЗАЦІЇ...
echo =====================================================================
echo.
echo  Будь ласка, зачекайте. Йде визначення конфігурації та налаштування...
echo.
start C:\kusnix\devicetweaker
goto autofinish


:autofinish
cls
echo =====================================================================
echo                 ЗАСТОСУВАННЯ АВТО-ОПТИМІЗАЦІЇ...
echo =====================================================================
echo.
echo  [+] Щоб застосувати авто-оптимізацію, вам треба:
echo  [+] Натиснути AUTO OPTIMIZATION
echo  [+] Далі по черзі: No, Yes, Both, Ok
echo  [+] Успіх! Можете перезавантажувати ПК для застосування всіх змін.
echo.
echo =====================================================================
echo.
pause
goto menu



:lockinro
cls
echo [!] Ввімкнення "Блокування маршрутизації переривань"...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringFlags" /t REG_DWORD /d 1 /f
echo [+] "Блокування маршрутизації переривань" успішно ввімкнено!
pause
goto menu
:all_tweaks
cls
echo Ви впевнені, що хочете примінити УСІ преміум твіки відразу?
echo [A] - Так, примінити  ^|  [X] - Ні, назад у меню
choice /c ax /n

if errorlevel 2 goto menu

cls
echo [!] Запуск повної оптимізації...
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /disable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /disable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /disable
start "" "C:\kusnix\pw.exe" "C:\kusnix\msync.bat"
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /disable
schtasks /change /tn "Microsoft\Windows\Chkdsk\ProactiveScan" /disable
schtasks /change /tn "Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /disable
schtasks /change /tn "Microsoft\Windows\Diagnosis\Scheduled" /disable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /disable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\Diagnostics" /disable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\StorageSense" /disable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /disable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /disable
schtasks /change /tn "Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /disable
schtasks /change /tn "Microsoft\Windows\Server Manager\ServerManager" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierdaily" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierinstall" /disable
schtasks /change /tn "Microsoft\Windows\WindowsColorSystem\Calibration Loader" /disable
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /disable
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /disable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /disable
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /disable
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /disable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /disable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /disable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /disable
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /disable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackgroundUploadTask" /disable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackupTask" /disable
schtasks /change /tn "Microsoft\Windows\SettingSync\NetworkStateChangeTask" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /disable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /disable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /disable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /disable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /disable
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /disable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /disable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /disable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /disable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /disable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /disable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /disable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /disable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /disable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /disable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /disable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /disable

echo.
echo [+] ВСІ налаштування успішно активовано!
pause
goto menu
:revert
cls
timeout /t 1 /nobreak > nul
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% RESTORE / FIXES %C_MUTED%│ Відновлення системних компонентів%C_BORDER%                 ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[!] УВАГА: ЦЕ СТОРІНКА ВИПРАВЛЕНЬ ТА ВІДНОВЛЕННЯ НАЛАШТУВАНЬ%C_BORDER%       ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Увімкнути Win Insider       %C_NUM%[10]%C_TEXT% Увімкнути Очищення        %C_BORDER%   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Увімкнути Аналіз            %C_NUM%[11]%C_TEXT% Увімкнути MS Store        %C_BORDER%   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Увімкнути Діагностику       %C_NUM%[12]%C_TEXT% Увімкнути Xbox Live       %C_BORDER%   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Увімкнути Проксі            %C_NUM%[13]%C_TEXT% Увімкнути Політики        %C_BORDER%   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Увімкнути Мови              %C_NUM%[14]%C_TEXT% Увімкнути Завдання HDD   %C_BORDER%    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[6]%C_TEXT%  Увімкнути Продуктивність    %C_NUM%[15]%C_TEXT% Увімкнути Сповіщення     %C_BORDER%    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[7]%C_TEXT%  Увімкнути Карти/Гео         %C_NUM%[16]%C_TEXT% Скинути SystemResponsiv. %C_BORDER%    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[8]%C_TEXT%  Увімкнути Віддалене керув.  %C_NUM%[17]%C_TEXT% Увімкнути Зарезерв. схов.%C_BORDER%    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[9]%C_TEXT%  Увімкнути Синхронізацію MS  %C_NUM%[18]%C_TEXT% Вимкн. блокув. переривань%C_BORDER%    ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Головне Меню                                                   %C_BORDER%║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[A]  ЗАСТОСУВАТИ УСІ ВИПРАВЛЕННЯ ВІДРАЗУ%C_BORDER%                           ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Обери варіант %C_MUTED%(1-18, M, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" goto rtweak1
if "%choice%"=="2" goto rtweak2
if "%choice%"=="3" goto rtweak3
if "%choice%"=="4" goto rtweak4
if "%choice%"=="5" goto rtweak5
if "%choice%"=="6" goto rtweak6
if "%choice%"=="7" goto rtweak7
if "%choice%"=="8" goto rtweak8
if "%choice%"=="9" goto rtweak9
if "%choice%"=="10" goto rtweak10
if "%choice%"=="11" goto rtweak11
if "%choice%"=="12" goto rtweak12
if "%choice%"=="13" goto rtweak13
if "%choice%"=="14" goto rtweak14
if "%choice%"=="15" goto rtweak15
if "%choice%"=="16" goto rtweak16
if "%choice%"=="17" goto rtweak17
if "%choice%"=="17" goto rtweak18
if /i "%choice%"=="a" goto rall_tweaks
if /i "%choice%"=="M" goto menu

echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto revert
:rtweak1
cls
echo [!] Застосування Виправлення 1...
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /enable
echo [+] Виправлення 1 успішно застосовано!
pause
goto revert

:rtweak2
cls
echo [!] Застосування Виправлення 2...
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /enable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /enable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /enable
echo [+] Виправлення 2 успішно застосовано!
pause
goto revert

:rtweak3
cls
echo [!] Застосування Виправлення 3...
schtasks /change /tn "Microsoft\Windows\Chkdsk\ProactiveScan" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\Scheduled" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\Diagnostics" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\StorageSense" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /enable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable
schtasks /change /tn "Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\ServerManager" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierdaily" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierinstall" /enable
schtasks /change /tn "Microsoft\Windows\WindowsColorSystem\Calibration Loader" /enable
echo [+] Виправлення 3 успішно застосовано!
pause
goto revert

:rtweak4
cls
echo [!] Застосування Виправлення 4...
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /enable
echo [+] Виправлення 4 успішно застосовано!
pause
goto revert

:rtweak5
cls
echo [!] Застосування Виправлення 5...
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /enable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /enable
echo [+] Виправлення 5 успішно застосовано!
pause
goto revert

:rtweak6
cls
echo [!] Застосування Виправлення 6...
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /enable
echo [+] Виправлення 6 успішно застосовано!
pause
goto revert

:rtweak7
cls
echo [!] Застосування Виправлення 7...
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /enable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /enable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /enable
echo [+] Виправлення 7 успішно застосовано!
pause
goto revert

:rtweak8
cls
echo [!] Застосування Виправлення 8...
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /enable
echo [+] Виправлення 8 успішно застосовано!
pause
goto revert

:rtweak9
cls
echo [!] Застосування Виправлення 9...
start "" "C:\kusnix\pw.exe" "C:\kusnix\msyncc.bat"
schtasks /change /tn "Microsoft\Windows\SettingSync\NetworkStateChangeTask" /enable
echo [+] Виправлення 9 успішно застосовано!
pause
goto revert

:rtweak10
cls
echo [!] Застосування Виправлення 10...
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /enable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /enable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /enable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /enable
echo [+] Виправлення 10 успішно застосовано!
pause
goto revert

:rtweak11
cls
echo [!] Застосування Виправлення 11...
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /enable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /enable
echo [+] Виправлення 11 успішно застосовано!
pause
goto revert

:rtweak12
cls
echo [!] Застосування Виправлення 12...
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /enable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /enable
echo [+] Виправлення 12 успішно застосовано!
pause
goto revert

:rtweak13
cls
echo [!] Застосування Виправлення 13...
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /enable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /enable
echo [+] Виправлення 13 успішно застосовано!
pause
goto revert

:rtweak14
cls
echo [!] Застосування Виправлення 14...
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /enable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /enable
echo [+] Виправлення 14 успішно застосовано!
pause
goto revert

:rtweak15
cls
echo [!] Застосування Виправлення 15...
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /enable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /enable
echo [+] Виправлення 15 успішно застосовано!
pause
goto revert

:rtweak16
cls
echo [!] Застосування Виправлення 16...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f
echo [+] Виправлення 16 успішно застосовано!
pause
goto revert

:rtweak17
cls
echo [!] Застосування Виправлення 17...
DISM.exe /Online /Set-ReservedStorageState /State:Enabled
echo [+] Виправлення 17 успішно застосовано!
pause
goto revert

:rtweak18
cls
echo [!] Застосування Виправлення 18...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringFlags" /f
echo [+] Виправлення 18 успішно застосовано!
pause
goto revert
:rall_tweaks
cls
echo Ви впевнені, що хочете примінити УСІ виправлення відразу?
echo [A] - Так, примінити  ^|  [X] - Ні, назад у меню
choice /c ax /n

if errorlevel 2 goto revert

cls
echo [!] Запуск повної оптимізації...
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /enable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /enable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /enable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /enable
schtasks /change /tn "Microsoft\Windows\Chkdsk\ProactiveScan" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\Scheduled" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\Diagnostics" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\StorageSense" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /enable
schtasks /change /tn "Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\ServerManager" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierdaily" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierinstall" /enable
schtasks /change /tn "Microsoft\Windows\WindowsColorSystem\Calibration Loader" /enable
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /enable
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /enable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /disable
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /enable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /enable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /enable
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackgroundUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackupTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\NetworkStateChangeTask" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /enable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /enable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /enable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /enable
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /enable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /enable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /enable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /enable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /enable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /enable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /enable
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f
DISM.exe /Online /Set-ReservedStorageState /State:Enabled
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringFlags" /f
echo.
echo [+] ВСІ виправлення успішно активовано!
pause
goto revert