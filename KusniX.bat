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
    echo Поточне значення = 1. Змінюю на 0...
    reg add "%regKey%" /v %valName% /t REG_DWORD /d 0 /f
    echo Перезапускаю Explorer...
    taskkill /f /im explorer.exe
    start explorer.exe
) else (
    echo Значення вже 0 або відсутнє, змін не потрібно.
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
    echo Запуск с правами администратора...
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
echo             		 Custom BoosterX Tweaker[v1.5]
echo ================================================================================
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
if "%choice%"=="6" start "" "c:\kusnix\interrupts\lockinro.bat" & goto menu

if /i "%choice%"=="r" goto revert

echo ...
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
echo  %C_BORDER%║%RESET%   %C_NUM%[8]%C_TEXT%  Віддалене керування         %C_NUM%[16]%C_TEXT% Крос-девайс продовження      %C_BORDER%║%RESET%
echo  %C_BORDER%║%RESET%   %C_NUM%[17]%C_TEXT% Вимкнути FSO                                                  %C_BORDER%║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Головне Меню            %C_GREEN%[R]%C_MUTED% Сторінка виправлень (Увімкнути...)%C_BORDER% ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_ACCENT%[A]  ЗАСТОСУВАТИ УСІ ТВІКИ ВІДРАЗУ%C_BORDER%                               %C_BORDER%  ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Обери варіант %C_MUTED%(1-17, M, R, A)%C_TEXT%: %RESET%"
 
if "%choice%"=="1" start "" "c:\kusnix\wintasks\twinsider" & goto wintasks
if "%choice%"=="2" start "" "c:\kusnix\wintasks\tanalisys" & goto wintasks
if "%choice%"=="3" start "" "c:\kusnix\wintasks\tdiagn" & goto wintasks
if "%choice%"=="4" start "" "c:\kusnix\wintasks\tproxy" & goto wintasks
if "%choice%"=="5" start "" "c:\kusnix\wintasks\tlang" & goto wintasks
if "%choice%"=="6" start "" "c:\kusnix\wintasks\tperf" & goto wintasks
if "%choice%"=="7" start "" "c:\kusnix\wintasks\tmaps" & goto wintasks
if "%choice%"=="8" start "" "c:\kusnix\wintasks\tanyd" & goto wintasks
if "%choice%"=="9" start "" "c:\kusnix\wintasks\pw.exe" "c:\kusnix\wintasks\msync" & goto wintasks
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
echo Якщо у вас драйвер мережевого адаптера(Wifi,Ethernet) на базі NDIS
echo.
echo - Застосуйте файл Optimized-MMCSS-Settings.reg
echo - Перевірте наявність затримок звуку в грі
echo - Якщо затримок звуку немає, то більше нічого не змінюйтe
echo - Якщо затримки звуку є (слабкий процесор + NVIDIA у версіях W11 24H2+)
echo   то застосуйте Audio-Stutters-Fix.reg
echo.
echo Якщо у вас драйвер мережевого адаптера(Wifi,Ethernet) на базі NetAdapterCx
echo.
echo - Застосуйте Disable-MMCSS.reg
echo - Перевірте наявність переривань звуку в грі
echo - Якщо затримок звуку немає, то більше нічого не змінюйтe
echo - Якщо затримки звуку є (слабкий процесор + NVIDIA у версіях W11 24H2+)
echo   то застосуйте Enable-MMCSS.reg та Optimized-MMCSS-Settings.reg
echo.
echo - Якщо затримки не зникли, застосуйте Audio-Stutters-Fix.reg
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
echo            Завантаження сторінки: Налаштування мережевого адаптера
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
if "%choice%"=="2" start C:\kusnix\interrupts\devicetweaker.bat & goto interrupts
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
start C:\kusnix\interrupts\devicetweaker.bat
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
echo  %C_BORDER%║%RESET%   %C_NUM%[19]%C_TEXT% Увімкнути крос-девайс       %C_NUM%[20]%C_TEXT% Ввімкнути FSO	%C_BORDER%        ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╠══════════════════════════════════════════════════════════════════════╣%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[M]%C_MUTED% Головне Меню                                                   %C_BORDER%║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%║%RESET%   %C_GREEN%[A]  ЗАСТОСУВАТИ УСІ ВИПРАВЛЕННЯ ВІДРАЗУ%C_BORDER%                           ║%RESET%
echo  %C_BORDER%║                                                                      ║%RESET%
echo  %C_BORDER%╚══════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set /p choice="%C_PROMPT%  ❯%C_TEXT% Обери варіант %C_MUTED%(1-20, M, A)%C_TEXT%: %RESET%"

if "%choice%"=="1" start "" "c:\kusnix\revertpage\rtwininsider" & goto revert
if "%choice%"=="2" start "" "c:\kusnix\revertpage\rtclean" & goto revert
if "%choice%"=="3" start "" "c:\kusnix\revertpage\rtanalysis" & goto revert
if "%choice%"=="4" start "" "c:\kusnix\revertpage\rtproxy" & goto revert
if "%choice%"=="5" start "" "c:\kusnix\revertpage\rtlang" & goto revert
if "%choice%"=="6" start "" "c:\kusnix\revertpage\rtperf" & goto revert
if "%choice%"=="7" start "" "c:\kusnix\revertpage\rtmaps" & goto revert
if "%choice%"=="8" start "" "c:\kusnix\revertpage\rtanyd" & goto revert
if "%choice%"=="9" start "" "c:\kusnix\wintasks\pw.exe" "c:\kusnix\revertpage\msyncc" & goto revert 
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
if "%choice%"=="M" goto menu

echo ...
timeout /t 1 > nul
goto revert