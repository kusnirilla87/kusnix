@echo off
setlocal EnableExtensions

chcp 65001 > nul
title KusniX Custom BoosterX
mode con: cols=80 lines=32
color 0A
setlocal enabledelayedexpansion

set "regKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
set "valName=HideFileExt"

rem Зчитуємо поточне значення
for /f "tokens=3" %%A in ('reg query "%regKey%" /v %valName% 2^>nul ^| findstr /i "%valName%"') do (
    set "curVal=%%A"
)

if "!curVal!"=="0x1" (
    echo now = 1. Змінюю на 0...
    reg add "%regKey%" /v %valName% /t REG_DWORD /d 0 /f
    echo restarting Explorer...
    taskkill /f /im explorer.exe
    start explorer.exe
) else (
    echo 0 already,not changing
)

endlocal
for /F "tokens=1 delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "C_BORDER=%ESC%[38;2;51;65;85m"        :: Темно-сірий бордюр
set "C_TITLE=%ESC%[38;2;56;189;248m%ESC%[1m"   :: Блакитний заголовок
set "C_NUM=%ESC%[38;2;251;191;36m%ESC%[1m"     :: Жовті індекси
set "C_TEXT=%ESC%[38;2;226;232;240m"      :: Яскравий білий текст
set "C_MUTED=%ESC%[38;2;100;116;139m"    :: Приглушений сірий
set "C_ACCENT=%ESC%[38;2;244;63;94m%ESC%[1m"   :: Червоний акцент
set "C_GREEN=%ESC%[38;2;74;222;128m%ESC%[1m"   :: Зелений
set "C_PROMPT=%ESC%[38;2;168;85;247m%ESC%[1m"  :: Фіолетовий промпт
set "RESET=%ESC%[0m"


if "%1"=="admin" goto menu

:: Проверка прав
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
echo             		        Tweaker[v1.6]
echo ================================================================================
echo.
echo			[1] Windows Tasks Configuration
echo.
echo		        [2] MMCSS Tweaks Configuration
echo.
echo			[3] Disk Cleanup (cache, junk, leftovers...)		        
echo.
echo			[4] Network Adapter (Ethernet) Configuration
echo.
echo			[5] Interrupts Configuration
echo.
echo			[6] Enable "Lock Interrupt Routing"
echo.		
echo.
echo ================================================================================   		
echo.
echo			[R] Revert Page (Enable...)
echo.
echo ================================================================================
set /p choice="Choose (1-6, R): "

if "%choice%"=="1" goto wintasks
if "%choice%"=="2" goto MMCSStweaks
if "%choice%"=="3" goto diskclean
if "%choice%"=="4" goto netadapter
if "%choice%"=="5" goto interrupts
if "%choice%"=="6" start "" "c:\kusnix\interrupts\lockinro.bat" & goto menu

if /i "%choice%"=="r" goto revert

echo ...
timeout /t 1 > nul
goto menu

:wintasks
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo                	    Loading Page: Windows Tasks
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
echo  %C_BORDER%║%RESET% %C_TITLE% WINDOWS TASKS %C_MUTED%│ Task Scheduler optimization%C_BORDER%                         ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Windows Insider Task        %C_NUM%[9]%C_TEXT%  Microsoft Sync               %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Analytics Tasks             %C_NUM%[10]%C_TEXT% Cleanup Tasks                %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Diagnostics Tasks           %C_NUM%[11]%C_TEXT% Microsoft Store Tasks        %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Proxy Auto-Detection        %C_NUM%[12]%C_TEXT% Xbox Live Tasks              %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Language Install/Removal    %C_NUM%[13]%C_TEXT% Policy Update                %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[6]%C_TEXT%  Performance Auto-Check      %C_NUM%[14]%C_TEXT% HDD Tasks                    %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[7]%C_TEXT%  Maps ^& GPS	              %C_NUM%[15]%C_TEXT% EOL Notifications            %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[8]%C_TEXT%  Remote Management           %C_NUM%[16]%C_TEXT% Cross-Device Resume          %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[17]%C_TEXT% Disable FSO%C_BORDER%                                                   ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Main Menu                  %C_GREEN%[R]%C_MUTED% Fixes Page (Enable...)%C_BORDER%          ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[A]  APPLY ALL TWEAKS AT ONCE%C_BORDER%                                      ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Choose %C_MUTED%(1-17, M, R, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" start "" "c:\kusnix\wintasks\twinsider" & goto wintasks
if "%choice%"=="2" start "" "c:\kusnix\wintasks\tanalisys" & goto wintasks
if "%choice%"=="3" start "" "c:\kusnix\wintasks\tdiagn" & goto wintasks
if "%choice%"=="4" start "" "c:\kusnix\wintasks\tproxy" & goto wintasks
if "%choice%"=="5" start "" "c:\kusnix\wintasks\tlang" & goto wintasks
if "%choice%"=="6" start "" "c:\kusnix\wintasks\tperf" & goto wintasks
if "%choice%"=="7" start "" "c:\kusnix\wintasks\tmaps" & goto wintasks
if "%choice%"=="8" start "" "c:\kusnix\wintasks\tanyd" & goto wintasks
if "%choice%"=="9" start "" "C:\kusnix\WinTasks\pw.exe" cmd.exe /c "C:\kusnix\WinTasks\msync.bat" & goto wintasks
if "%choice%"=="10" start "" "c:\kusnix\wintasks\tclean" & goto wintasks
if "%choice%"=="11" start "" "c:\kusnix\wintasks\tmstore" & goto wintasks
if "%choice%"=="12" start "" "c:\kusnix\wintasks\txbox" & goto wintasks
if "%choice%"=="13" start "" "c:\kusnix\wintasks\tpolicy" & goto wintasks
if "%choice%"=="14" start "" "c:\kusnix\wintasks\thdd" & goto wintasks
if "%choice%"=="15" start "" "c:\kusnix\wintasks\teol" & goto wintasks
if "%choice%"=="16" start "" "c:\kusnix\wintasks\crossdevice" & goto wintasks
if "%choice%"=="17" start "" "c:\kusnix\wintasks\fse" & goto wintasks
if /i "%choice%"=="a" start "" "c:\kusnix\wintasks\all_tweaks" & goto wintasks
if /i "%choice%"=="r" goto revert
if /i "%choice%"=="m" goto menu
echo ...
timeout /t 1 > nul
goto wintasks



:MMCSStweaks
cls
call C:\kusnix\mmcss\checknic.bat
echo If your network adapter driver (Wifi,Ethernet) is NDIS-based
echo.
echo - Apply the Optimized-MMCSS-Settings.reg file
echo - Check for audio delays in the game
echo - If there are no audio delays, do not change anything else
echo - If there are audio delays (weak CPU + NVIDIA on W11 24H2+ versions)
echo   then apply Audio-Stutters-Fix.reg
echo.
echo If your network adapter driver (Wifi,Ethernet) is NetAdapterCx-based
echo.
echo - Apply Disable-MMCSS.reg
echo - Check for audio interruptions in the game
echo - If there are no audio delays, do not change anything else
echo - If there are audio delays (weak CPU + NVIDIA on W11 24H2+ versions)
echo   then apply Enable-MMCSS.reg and Optimized-MMCSS-Settings.reg
echo.
echo - If the delays did not go away, apply Audio-Stutters-Fix.reg
echo.
echo.
echo [1] Optimized-MMCSS-Settings.reg
echo [2] Disable-MMCSS.reg
echo [3] Enable-MMCSS.reg
echo [4] Audio-Stutters-Fix.reg
echo [M] Головне меню
set /p choice=: 
if "%choice%"=="1" start "" "c:\kusnix\mmcss\optmmcss.bat" 
if "%choice%"=="2" start "" "c:\kusnix\mmcss\dismmcss.bat" 
if "%choice%"=="3" start "" "c:\kusnix\mmcss\enmmcss.bat" 
if "%choice%"=="4" start "" "c:\kusnix\mmcss\audiofixmmcss.bat" 
if "%choice%"=="m" goto menu
echo ...
timeout /t 1 > nul
goto MMCSStweaks
pause
goto menu

:diskclean
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo                	     Loading Page: Disk Cleanup
echo             ====================================================
echo                [████████████████████████████████████████] 100%%
echo             ====================================================
timeout 1 >nul
cls
chcp 65001 > nul
cls
echo.
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% DISK CLEANUP %C_MUTED%│ Disk maintenance system%C_BORDER%                                  ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_MUTED%[ MAIN OPERATIONS ]%C_BORDER%                                                    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Disable "Update Reserved Storage"%C_BORDER%                                 ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Clear "Windows Update Cache"%C_BORDER%                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Additional advanced cache cleanup%C_BORDER%                                 ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Removed UWP apps (leftovers)%C_BORDER%                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Clear activity traces%C_BORDER%                                             ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED%  Main Menu              %C_GREEN%[R]%C_MUTED%  Fixes Page (Enable...)%C_BORDER%                ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[A]  CLEAN EVERYTHING INSTANTLY%C_BORDER%                                        ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Choose %C_MUTED%(1-5, M, R, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" start "" "c:\kusnix\diskclean\restorage.bat" & goto diskclean
if "%choice%"=="2" start "" "c:\kusnix\diskclean\winupdatecache" & goto diskclean
if "%choice%"=="3" start "" "c:\kusnix\diskclean\advanclean.bat" & goto diskclean
if "%choice%"=="4" start "" "c:\kusnix\diskclean\deluwp.bat" & goto diskclean
if "%choice%"=="5" start "" "c:\kusnix\diskclean\activityclean.bat" & goto diskclean

if /i "%choice%"=="a" start "" "c:\kusnix\diskclean\all_cleans.bat" & goto diskclean
if /i "%choice%"=="r" goto revert
if /i "%choice%"=="m" goto menu
echo ...
timeout /t 1 > nul
goto diskclean

:netadapter
cls
for /L %%i in (1, 1, 27) do echo.
echo             ====================================================
echo            	   Loading Page: Network Adapter
echo             ====================================================
echo                [████████████████████████████████████████] 100%%
echo             ====================================================
timeout 1 >nul
cls
start "" "c:\kusnix\netadapter\netadapterpreset.bat
goto menu

:interrupts
cls
for /L %%i in (1, 1, 27) do echo.
echo              ====================================================
echo                 	Loading Page: Interrupts
echo              ====================================================
echo                 [████████████████████████████████████████] 100%%
echo              ====================================================
timeout 1 >nul
cls
cls
echo.
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% INTERRUPTS %C_MUTED%│ MSI ^& CPU management%C_BORDER%                                       ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_MUTED%[ MODULE OVERVIEW ]%C_BORDER%                                                    ║%RESET%
echo  %C_BORDER%║%RESET%   %C_TEXT%Automated suite for optimizing interrupt handling:%C_BORDER%                     ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%▸ %C_TEXT%Switch devices to MSI mode (Message Signaled Interrupts)%C_BORDER%             ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%▸ %C_TEXT%Balance IRQ priorities and pin them to CPU threads%C_BORDER%                   ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%▸ %C_TEXT%Fix and distribute network RSS queues (Receive Side Scaling)%C_BORDER%         ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_MUTED%[ SELECT ACTION ]%C_BORDER%                                                      ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Run automatic configuration%C_BORDER%                                       ║%RESET%
echo  %C_BORDER%║%RESET%        %C_MUTED%Applies optimal settings for your hardware in one pass%C_BORDER%            ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Go to manual configuration%C_BORDER%                                        ║%RESET%
echo  %C_BORDER%║%RESET%        %C_MUTED%Choose devices, IRQ priorities and CPU affinity yourself%C_BORDER%          ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED%  Back to main menu%C_BORDER%                                                 ║%RESET%
echo  %C_BORDER%║                                                                          ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Choose %C_MUTED%(1, 2, M)%C_TEXT%: %RESET%"
if "%choice%"=="1" goto autointerrupts
if "%choice%"=="2" start C:\kusnix\interrupts\devicetweaker.bat & goto interrupts
if "%choice%"=="m" goto menu
echo Невірний вибір, спробуй ще раз...
timeout /t 1 > nul
goto interrupts

:autointerrupts
cls
echo =====================================================================
echo                   	     AUTO-OPTIMIZATION...
echo =====================================================================
echo.
echo  Please wait. Checking your PC specifications...
echo.
start C:\kusnix\interrupts\devicetweaker.bat
goto autofinish


:autofinish
cls
echo =====================================================================
echo                 	    AUTO-OPTIMIZATION...
echo =====================================================================
echo.
echo  [+] To apply the auto-optimization, you need to:
echo  [+] Click AUTO OPTIMIZATION
echo  [+] Then, one by one: No, Yes, Both, Ok
echo  [+] Success! You can restart your PC to apply all changes.
echo.
echo =====================================================================
echo.
pause
goto menu

:revert
cls
timeout /t 1 /nobreak > nul
echo  %C_BORDER%╔══════════════════════════════════════════════════════════════════════╗%RESET%
echo  %C_BORDER%║%RESET% %C_TITLE% RESTORE / FIXES %C_MUTED%│ System components restoration%C_BORDER%                     ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[!] WARNING: THIS IS THE FIXES AND SETTINGS RESTORATION PAGE%C_BORDER%       ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[1]%C_TEXT%  Enable Win Insider          %C_NUM%[10]%C_TEXT% Enable Cleanup               %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[2]%C_TEXT%  Enable Analytics            %C_NUM%[11]%C_TEXT% Enable MS Store              %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[3]%C_TEXT%  Enable Diagnostics          %C_NUM%[12]%C_TEXT% Enable Xbox Live             %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[4]%C_TEXT%  Enable Proxy                %C_NUM%[13]%C_TEXT% Enable Policies              %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[5]%C_TEXT%  Enable Languages            %C_NUM%[14]%C_TEXT% Enable HDD Tasks             %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[6]%C_TEXT%  Enable Performance          %C_NUM%[15]%C_TEXT% Enable Notifications         %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[7]%C_TEXT%  Enable Maps/Geo             %C_NUM%[16]%C_TEXT% Reset SystemResponsiveness   %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[8]%C_TEXT%  Enable Remote Management    %C_NUM%[17]%C_TEXT% Enable Reserved Storage      %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[9]%C_TEXT%  Enable Microsoft Sync       %C_NUM%[18]%C_TEXT% Disable interrupt blocking   %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[19]%C_TEXT% Enable Cross-Device         %C_NUM%[20]%C_TEXT% Enable FSO                   %C_BORDER%║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Main Menu%C_BORDER%                                                      ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[A]  APPLY ALL FIXES AT ONCE%C_BORDER%                                       ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Choose %C_MUTED%(1-20, M, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" start "" "c:\kusnix\revertpage\rtwininsider" & goto revert
if "%choice%"=="2" start "" "c:\kusnix\revertpage\rtclean" & goto revert
if "%choice%"=="3" start "" "c:\kusnix\revertpage\rtanalysis" & goto revert
if "%choice%"=="4" start "" "c:\kusnix\revertpage\rtproxy" & goto revert
if "%choice%"=="5" start "" "c:\kusnix\revertpage\rtlang" & goto revert
if "%choice%"=="6" start "" "c:\kusnix\revertpage\rtperf" & goto revert
if "%choice%"=="7" start "" "c:\kusnix\revertpage\rtmaps" & goto revert
if "%choice%"=="8" start "" "c:\kusnix\revertpage\rtanyd" & goto revert
if "%choice%"=="9" start "" "C:\kusnix\WinTasks\pw.exe" cmd.exe /c "C:\kusnix\WinTasks\msyncc.bat" & goto revert 
if "%choice%"=="10" start "" "c:\kusnix\revertpage\rtclean" & goto revert
if "%choice%"=="11" start "" "c:\kusnix\revertpage\rtmstore" & goto revert
if "%choice%"=="12" start "" "c:\kusnix\revertpage\rtxbox" & goto revert
if "%choice%"=="13" start "" "c:\kusnix\revertpage\rtpolicy" & goto revert
if "%choice%"=="14" start "" "c:\kusnix\revertpage\rthdd" & goto revert
if "%choice%"=="15" start "" "c:\kusnix\revertpage\rteol" & goto revert
if "%choice%"=="16" start "" "c:\kusnix\revertpage\rsysrespon" & goto revert
if "%choice%"=="17" start "" "c:\kusnix\revertpage\rrestorage" & goto revert
if "%choice%"=="18" start "" "c:\kusnix\revertpage\rlockinro" & goto revert
if "%choice%"=="19" start "" "c:\kusnix\revertpage\rcrossdevice" & goto revert
if "%choice%"=="20" start "" "c:\kusnix\revertpage\fso.reg" & goto revert
if "%choice%"=="a" start "" "c:\kusnix\revertpage\rall_tweaks" & goto revert
if "%choice%"=="m" goto menu

echo ...
timeout /t 1 > nul
goto revert