#requires -RunAsAdministrator
# =====================================================================
#  NetAdapterPreset.ps1
#  Автовизначення провід/Wi-Fi + Intel/Realtek, застосування пресетів
#  розширених властивостей (Advanced Properties).
#
#  Профілі:  1) Домашній ноутбук   2) Робочий ноутбук
#            3) Домашній ПК        4) Ігровий ПК/ноутбук
#
#  Режими роботи:
#    A) Авто   - визначає активний адаптер і його тип сам
#    B) Ручний - показує список усіх адаптерів, вибираєш потрібний
#    C) Обидва - застосовує пресет одразу і на Ethernet, і на Wi-Fi
# =====================================================================

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off
$origEAP = $ErrorActionPreference

function Write-Banner {
    $line = "═" * 71
    Write-Host ""
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host "   N E T   A D A P T E R   P R E S E T   M A N A G E R" -ForegroundColor Cyan
    Write-Host "   Intel / Realtek  •  Ethernet / Wi-Fi  •  Advanced Properties" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor DarkCyan
}

function Write-Head($t) {
    Write-Host ""
    Write-Host ("┌─ {0} " -f $t) -ForegroundColor Cyan -NoNewline
    Write-Host ("─" * [Math]::Max(1, 66 - $t.Length)) -ForegroundColor DarkCyan
}

function Write-Sub($t, $color = "Gray") {
    Write-Host ("   │ " + $t) -ForegroundColor $color
}

# ---------------------------------------------------------------------
# Допоміжна функція застосування властивості
# ---------------------------------------------------------------------
function Set-Prop {
    param(
        [string]$Adapter,
        [string]$Keyword,
        [string]$Value,
        [string]$Comment = ""
    )
    try {
        $null = Get-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -ErrorAction Stop
        Set-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -RegistryValue $Value -ErrorAction Stop
        Write-Host ("   [") -ForegroundColor DarkGray -NoNewline
        Write-Host ("OK") -ForegroundColor Green -NoNewline
        Write-Host ("]   {0,-28} -> {1,-6}  " -f $Keyword, $Value) -ForegroundColor White -NoNewline
        Write-Host $Comment -ForegroundColor DarkGray
    } catch {
        Write-Host ("   [") -ForegroundColor DarkGray -NoNewline
        Write-Host ("SKIP") -ForegroundColor Yellow -NoNewline
        Write-Host ("] {0,-28} (властивість відсутня на цьому адаптері)" -f $Keyword) -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------
# Визначення типу (Ethernet/Wi-Fi) та виробника (Intel/Realtek)
# ---------------------------------------------------------------------
function Get-AdapterKind {
    param($Adapter)
    $isWifi = ($Adapter.PhysicalMediaType -match 'Native 802.11|Wireless') -or ($Adapter.MediaType -match '802.11')
    return $(if ($isWifi) { "WiFi" } else { "Ethernet" })
}

function Get-AdapterVendor {
    param($Adapter)
    $desc = $Adapter.InterfaceDescription
    if ($desc -match 'Intel') { return "Intel" }
    if ($desc -match 'Realtek') { return "Realtek" }
    return "Unknown"
}

# ---------------------------------------------------------------------
# Реєстраційний шлях адаптера (клас мережевих адаптерів)
# ---------------------------------------------------------------------
$script:ClassRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'

function Get-AdapterRegistryPath {
    param($Adapter)
    $found = $null
    Get-ChildItem $script:ClassRoot -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.PSPath
        $val = (Get-ItemProperty -Path $p -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue).NetCfgInstanceId
        if ($val -eq $Adapter.InterfaceGuid) {
            $script:found = $p -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
        }
    }
    return $script:found
}

# ---------------------------------------------------------------------
# Визначення типу драйвера: NDIS (legacy) чи NetAdapterCx (сучасний)
# Логіка з CHECK-NIC-DRIVER-TYPE.ps1
# ---------------------------------------------------------------------
function Resolve-DriverImagePath {
    param([string]$ImagePath)
    if ([string]::IsNullOrWhiteSpace($ImagePath)) { return $null }
    $p = $ImagePath.Trim()
    if ($p -like '\SystemRoot*') {
        $p = $p -replace '^\\SystemRoot', $env:SystemRoot
    } elseif ($p -like 'System32*') {
        $p = Join-Path $env:SystemRoot $p
    } elseif ($p -match '^\\\?\?\\') {
        $p = $p -replace '^\\\?\?\\', ''
    }
    $p = $p -replace '%SystemRoot%', $env:SystemRoot

    $candidate = $null
    if ($p -match '(".*?\.sys")') { $candidate = $Matches[1].Trim('"') }
    elseif ($p -match '([A-Za-z]:\\.*?\.sys)') { $candidate = $Matches[1] }
    elseif ($p -match '(\\.*?\.sys)') { $candidate = $Matches[1] }
    else { $candidate = $p.Trim('"') }

    if (Test-Path $candidate -ErrorAction SilentlyContinue) { return $candidate }
    try {
        $alt = Join-Path $env:SystemRoot ($candidate.TrimStart('\'))
        if (Test-Path $alt -ErrorAction SilentlyContinue) { return $alt }
    } catch {}
    return $null
}

function Get-DriverTypeFromBinary {
    param([string]$SysPath)
    if (-not $SysPath -or -not (Test-Path $SysPath -ErrorAction SilentlyContinue)) { return "NDIS" }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($SysPath)
        $txt   = [System.Text.Encoding]::ASCII.GetString($bytes)
        if ($txt -match 'NetAdapter') { return "NetAdapterCx" }
        if ($txt -match 'NDIS\.SYS')  { return "NDIS" }
        return "Unknown"
    } catch {
        return "NDIS"
    }
}

function Get-AdapterDriverType {
    param($Adapter)
    $ErrorActionPreference = "SilentlyContinue"
    try {
        $pnp = $Adapter.PnPDeviceID
        if (-not $pnp) { return "Unknown" }
        $enumKey   = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnp"
        $driverKey = (Get-ItemProperty -Path $enumKey -Name "Driver" -ErrorAction SilentlyContinue).Driver
        if (-not $driverKey) { return "Unknown" }

        $ndiKey  = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driverKey\Ndi"
        $service = (Get-ItemProperty -Path $ndiKey -Name "Service" -ErrorAction SilentlyContinue).Service
        if (-not $service) { return "Unknown" }
        $service = $service.TrimEnd('.')

        $svcKey    = "HKLM:\SYSTEM\CurrentControlSet\Services\$service"
        $imagePath = (Get-ItemProperty -Path $svcKey -Name "ImagePath" -ErrorAction SilentlyContinue).ImagePath
        $resolved  = Resolve-DriverImagePath $imagePath
        return Get-DriverTypeFromBinary $resolved
    } catch {
        return "Unknown"
    } finally {
        $ErrorActionPreference = $origEAP
    }
}

# ---------------------------------------------------------------------
# Красива інфо-картка знайденого/обраного адаптера
# ---------------------------------------------------------------------
function Show-AdapterCard {
    param($Adapter)

    $kind       = Get-AdapterKind   $Adapter
    $vendor     = Get-AdapterVendor $Adapter
    $regPath    = Get-AdapterRegistryPath $Adapter
    $driverType = Get-AdapterDriverType   $Adapter

    $kindColor   = if ($kind -eq "WiFi") { "Magenta" } else { "Blue" }
    $vendorColor = if ($vendor -eq "Intel") { "Cyan" } elseif ($vendor -eq "Realtek") { "Yellow" } else { "Red" }
    $statusColor = if ($Adapter.Status -eq "Up") { "Green" } else { "DarkYellow" }
    $drvColor    = if ($driverType -eq "NetAdapterCx") { "Green" } elseif ($driverType -eq "NDIS") { "DarkCyan" } else { "DarkGray" }

    Write-Host ""
    Write-Host "  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" -ForegroundColor DarkGray
    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "АДАПТЕР ЗНАЙДЕНО" -ForegroundColor White -NoNewline
    Write-Host (" " * 46) -NoNewline
    Write-Host "┃" -ForegroundColor DarkGray
    Write-Host "  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫" -ForegroundColor DarkGray

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Назва       : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.Name -ForegroundColor White

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Опис        : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.InterfaceDescription -ForegroundColor DarkCyan

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Статус      : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.Status -ForegroundColor $statusColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Тип з'єднання: " -ForegroundColor Gray -NoNewline
    Write-Host $kind -ForegroundColor $kindColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Виробник    : " -ForegroundColor Gray -NoNewline
    Write-Host $vendor -ForegroundColor $vendorColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Тип драйвера: " -ForegroundColor Gray -NoNewline
    Write-Host $driverType -ForegroundColor $drvColor -NoNewline
    if ($driverType -eq "NetAdapterCx") {
        Write-Host "  (сучасний, повна підтримка Advanced Properties)" -ForegroundColor DarkGray
    } elseif ($driverType -eq "NDIS") {
        Write-Host "  (класичний NDIS-драйвер)" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Швидкість   : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.LinkSpeed -ForegroundColor White

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Реєстр      : " -ForegroundColor Gray -NoNewline
    if ($regPath) {
        Write-Host $regPath -ForegroundColor DarkYellow
    } else {
        Write-Host "не вдалося визначити" -ForegroundColor DarkGray
    }

    Write-Host "  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# ПРЕСЕТИ. Структура: $Presets[Vendor][Kind][Profile] = @{ Keyword=Value }
# Профілі: HomeLaptop, WorkLaptop, HomePC, GamePC
# Коментарі відповідають зібраним таблицям (intel/realtek eth/wifi).
# ---------------------------------------------------------------------

$Presets = @{}

# ===================== INTEL ETHERNET =====================
$Presets.Intel = @{}
$Presets.Intel.Ethernet = @{
    HomeLaptop = @{
        "ReduceSpeedOnPowerDown"  = @("1","Enabled (економія на батареї)")
        "SIPS"                    = @("1","System Idle Power Saver Enabled")
        "SmartPowerDownEnable"    = @("1","Link speed battery saver Enabled")
        "*EEE"                    = @("1","Enabled")
        "PME"                     = @("0","Enable PME Disabled")
        "*FlowControl"            = @("3","Enabled")
        "*InterruptModeration"    = @("1","Enabled")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 1/2")
    }
    WorkLaptop = @{
        "ReduceSpeedOnPowerDown"  = @("1","Enabled")
        "SIPS"                    = @("1","Enabled")
        "SmartPowerDownEnable"    = @("1","Enabled")
        "*EEE"                    = @("1","Enabled")
        "PME"                     = @("1","Enable PME Enabled")
        "*FlowControl"            = @("3","Enabled")
        "*InterruptModeration"    = @("1","Enabled")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 1/2")
    }
    HomePC = @{
        "ReduceSpeedOnPowerDown"  = @("0","Disabled (стаціонарний ПК)")
        "SIPS"                    = @("0","Disabled")
        "SmartPowerDownEnable"    = @("0","Disabled")
        "*EEE"                    = @("0","Disabled")
        "PME"                     = @("0","Disabled")
        "*FlowControl"            = @("3","Enabled")
        "*InterruptModeration"    = @("1","Enabled")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 2")
    }
    GamePC = @{
        "ReduceSpeedOnPowerDown"  = @("0","Disabled")
        "SIPS"                    = @("0","Disabled")
        "SmartPowerDownEnable"    = @("0","Disabled")
        "*EEE"                    = @("0","Disabled")
        "PME"                     = @("0","Disabled")
        "*FlowControl"            = @("0","Disabled (мін. джиттер)")
        "*InterruptModeration"    = @("0","Disabled (мін. затримка)")
        "ITR"                     = @("0","Interrupt moderation rate Disable")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 2/4")
    }
}

# ===================== INTEL WI-FI =====================
$Presets.Intel.WiFi = @{
    HomeLaptop = @{
        "UAPSDSupport"             = @("1","U-APSD Enabled")
        "ThroughputBooster"        = @("1","Enable")
        "RoamingPreferredBandType" = @("0","None")
        "RoamAggressiveness"       = @("2","Medium")
        "MimoPowerSaveMode"        = @("0","No SMPS")
        "IbssTxPower"              = @("50","Medium")
        "FatChannelIntolerant"     = @("0","Disable")
        "ChannelWidth24"           = @("1","40MHz")
        "ChannelWidth52"           = @("2","80MHz")
        "CtsToItself"              = @("1","CTS-to-Self")
        "PacketCoalescing"         = @("1","Enabled")
        "SleepModeWoWLAN"          = @("1","Enabled")
    }
    WorkLaptop = @{
        "UAPSDSupport"             = @("1","Enabled")
        "ThroughputBooster"        = @("0","Disable")
        "RoamingPreferredBandType" = @("0","None")
        "RoamAggressiveness"       = @("4","High")
        "MimoPowerSaveMode"        = @("1","Auto SMPS")
        "IbssTxPower"              = @("50","Medium")
        "FatChannelIntolerant"     = @("1","Enable")
        "ChannelWidth24"           = @("0","20MHz")
        "ChannelWidth52"           = @("2","80MHz")
        "CtsToItself"              = @("0","RTS/CTS")
        "PacketCoalescing"         = @("1","Enabled")
        "SleepModeWoWLAN"          = @("1","Enabled")
    }
    HomePC = @{
        "UAPSDSupport"             = @("0","Disabled")
        "ThroughputBooster"        = @("1","Enable")
        "RoamingPreferredBandType" = @("2","5GHz")
        "RoamAggressiveness"       = @("2","Medium")
        "MimoPowerSaveMode"        = @("0","No SMPS")
        "IbssTxPower"              = @("100","Maximum")
        "FatChannelIntolerant"     = @("0","Disable")
        "ChannelWidth24"           = @("1","40MHz")
        "ChannelWidth52"           = @("2","80MHz")
        "CtsToItself"              = @("1","CTS-to-Self")
        "PacketCoalescing"         = @("0","Disabled")
        "SleepModeWoWLAN"          = @("0","Disabled")
    }
    GamePC = @{
        "UAPSDSupport"             = @("0","Disabled")
        "ThroughputBooster"        = @("1","Enable")
        "RoamingPreferredBandType" = @("2","5GHz")
        "RoamAggressiveness"       = @("0","Lowest")
        "MimoPowerSaveMode"        = @("0","No SMPS")
        "IbssTxPower"              = @("100","Maximum")
        "FatChannelIntolerant"     = @("0","Disable")
        "ChannelWidth24"           = @("1","40MHz")
        "ChannelWidth52"           = @("2","80MHz")
        "CtsToItself"              = @("1","CTS-to-Self")
        "PacketCoalescing"         = @("0","Disabled")
        "SleepModeWoWLAN"          = @("0","Disabled")
    }
}

# ===================== REALTEK ETHERNET =====================
# Ключі й значення звірені з реального дампу реєстру (Ndi\params) картки
# Realtek PCIe GbE Family Controller користувача - 100% відповідність.
$Presets.Realtek = @{}
$Presets.Realtek.Ethernet = @{
    HomeLaptop = @{
        "*FlowControl"              = @("3","Rx & Tx Enabled")
        "*InterruptModeration"      = @("1","Enabled")
        "*NumRssQueues"             = @("1","1 Queue")
    }
    WorkLaptop = @{
        "*FlowControl"              = @("3","Rx & Tx Enabled")
        "*InterruptModeration"      = @("1","Enabled")
        "*NumRssQueues"             = @("1","1 Queue")
    }
    HomePC = @{
        "*FlowControl"              = @("3","Rx & Tx Enabled")
        "*InterruptModeration"      = @("1","Enabled")
        "*NumRssQueues"             = @("2","2 Queues")
    }
    GamePC = @{
        "*FlowControl"              = @("0","Disabled (мін. джиттер)")
        "*InterruptModeration"      = @("0","Disabled (мін. затримка)")
        "*NumRssQueues"             = @("4","4 Queues")
    }
}
# Спільні для Realtek Ethernet значення, однакові для всіх 4 профілів
# (взято 1:1 з твого realtekETHERNEt.txt - там ці рядки без розбивки по колонках):
foreach ($p in @("HomeLaptop","WorkLaptop","HomePC","GamePC")) {
    $Presets.Realtek.Ethernet[$p]["*EEE"]                    = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["AutoDisableGigabit"]      = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["EnableGreenEthernet"]     = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["GigaLite"]                = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["PowerSavingMode"]         = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["AdvancedEEE"]             = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["S5WakeOnLan"]             = @("0","Shutdown WOL Disabled")
    $Presets.Realtek.Ethernet[$p]["WolShutdownLinkSpeed"]    = @("1","100 Mbps First")
    $Presets.Realtek.Ethernet[$p]["*WakeOnMagicPacket"]      = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["*WakeOnPattern"]          = @("0","Disabled")
    $Presets.Realtek.Ethernet[$p]["*TCPChecksumOffloadIPv4"] = @("3","Rx & Tx Enabled")
    $Presets.Realtek.Ethernet[$p]["*TCPChecksumOffloadIPv6"] = @("3","Rx & Tx Enabled")
    $Presets.Realtek.Ethernet[$p]["*UDPChecksumOffloadIPv4"] = @("3","Rx & Tx Enabled")
    $Presets.Realtek.Ethernet[$p]["*UDPChecksumOffloadIPv6"] = @("3","Rx & Tx Enabled")
    $Presets.Realtek.Ethernet[$p]["*SpeedDuplex"]            = @("0","Auto Negotiation")
    $Presets.Realtek.Ethernet[$p]["*RSS"]                    = @("1","Enabled")
    $Presets.Realtek.Ethernet[$p]["*PriorityVLANTag"]        = @("3","Priority & VLAN Enabled")
    $Presets.Realtek.Ethernet[$p]["*PMARPOffload"]           = @("1","Enabled")
    $Presets.Realtek.Ethernet[$p]["*PMNSOffload"]            = @("1","Enabled")
    $Presets.Realtek.Ethernet[$p]["*LsoV2IPv4"]              = @("1","Enabled")
    $Presets.Realtek.Ethernet[$p]["*LsoV2IPv6"]              = @("1","Enabled")
    $Presets.Realtek.Ethernet[$p]["*JumboPacket"]            = @("1514","Disabled (без jumbo frames)")
    $Presets.Realtek.Ethernet[$p]["*IPChecksumOffloadIPv4"]  = @("3","Rx & Tx Enabled")
}

# ===================== REALTEK WI-FI =====================
# Ключі й значення звірені з реального дампу реєстру (Ndi\params) картки
# Realtek RTL8822CE 802.11ac PCIe Adapter користувача - 100% відповідність.
# Важливо: WakeOnDisconnect має ІНВЕРТОВАНИЙ enum (0=Enabled, 1=Disabled)!
$Presets.Realtek.WiFi = @{
    HomeLaptop = @{
        "WakeOnDisconnect"     = @("0","Sleep on WoWLAN disconnect: Enabled")
        "RegROAMSensitiveLevel"= @("75","Roaming Aggressiveness: Medium")
        "PreferBand"           = @("0","Preferred Band: No Preference")
        "ProtectionMode"       = @("1","CTS-to-self Enabled")
        "b40Intolerant"        = @("0","Fat Channel Intolerant: Disabled")
        "BW40MHzFor2G"         = @("1","2.4GHz: Auto (40MHz)")
    }
    WorkLaptop = @{
        "WakeOnDisconnect"     = @("0","Sleep on WoWLAN disconnect: Enabled")
        "RegROAMSensitiveLevel"= @("70","Roaming Aggressiveness: Medium-High")
        "PreferBand"           = @("0","Preferred Band: No Preference")
        "ProtectionMode"       = @("0","RTS/CTS Enabled")
        "b40Intolerant"        = @("1","Fat Channel Intolerant: Enabled")
        "BW40MHzFor2G"         = @("0","2.4GHz: 20MHz Only")
    }
    HomePC = @{
        "WakeOnDisconnect"     = @("1","Sleep on WoWLAN disconnect: Disabled")
        "RegROAMSensitiveLevel"= @("75","Roaming Aggressiveness: Medium")
        "PreferBand"           = @("2","Preferred Band: 5G first")
        "ProtectionMode"       = @("1","CTS-to-self Enabled")
        "b40Intolerant"        = @("0","Fat Channel Intolerant: Disabled")
        "BW40MHzFor2G"         = @("1","2.4GHz: Auto (40MHz)")
    }
    GamePC = @{
        "WakeOnDisconnect"     = @("1","Sleep on WoWLAN disconnect: Disabled")
        "RegROAMSensitiveLevel"= @("85","Roaming Aggressiveness: Lowest")
        "PreferBand"           = @("2","Preferred Band: 5G first")
        "ProtectionMode"       = @("1","CTS-to-self Enabled")
        "b40Intolerant"        = @("0","Fat Channel Intolerant: Disabled")
        "BW40MHzFor2G"         = @("1","2.4GHz: Auto (40MHz)")
    }
}
# Спільні для Realtek Wi-Fi значення, однакові для всіх 4 профілів
# (взято 1:1 з твого realtekWIFI.txt - рядки без розбивки по колонках):
foreach ($p in @("HomeLaptop","WorkLaptop","HomePC","GamePC")) {
    $Presets.Realtek.WiFi[$p]["WirelessMode"]         = @("7","Default (802.11a/b/g + n/ac)")
    $Presets.Realtek.WiFi[$p]["*WakeOnMagicPacket"]   = @("0","Disabled")
    $Presets.Realtek.WiFi[$p]["*WakeOnPattern"]       = @("0","Disabled")
    $Presets.Realtek.WiFi[$p]["TxPwrLevel"]           = @("0","Highest")
    $Presets.Realtek.WiFi[$p]["PreambleMode"]         = @("2","Short & long")
    $Presets.Realtek.WiFi[$p]["ARPOffloadEnable"]     = @("1","Enabled")
    $Presets.Realtek.WiFi[$p]["NSOffloadEnable"]      = @("1","Enabled")
    $Presets.Realtek.WiFi[$p]["MultiChannelFcsMode"]  = @("28","Enabled + Hotspot")
    $Presets.Realtek.WiFi[$p]["GTKOffloadEnable"]     = @("1","Enabled")
    $Presets.Realtek.WiFi[$p]["BW40MHzFor5G"]         = @("1","Auto (80MHz)")
}

$ProfileNames = @{
    "1" = "HomeLaptop"
    "2" = "WorkLaptop"
    "3" = "HomePC"
    "4" = "GamePC"
}
$ProfileLabels = @{
    "HomeLaptop" = "Домашній ноутбук"
    "WorkLaptop" = "Робочий ноутбук"
    "HomePC"     = "Домашній ПК"
    "GamePC"     = "Ігровий ПК/ноутбук"
}

# ---------------------------------------------------------------------
# Застосування пресету до конкретного адаптера
# ---------------------------------------------------------------------
function Apply-Preset {
    param($Adapter, [string]$ProfileKey)

    $kind   = Get-AdapterKind   $Adapter
    $vendor = Get-AdapterVendor $Adapter

    Write-Head "$($Adapter.Name) [$vendor $kind] -> $($ProfileLabels[$ProfileKey])"

    if ($vendor -eq "Unknown") {
        Write-Host "  Не вдалось визначити виробника (не Intel/Realtek). Пропущено." -ForegroundColor Red
        return
    }
    if (-not $Presets.ContainsKey($vendor) -or -not $Presets[$vendor].ContainsKey($kind)) {
        Write-Host "  Немає пресету для $vendor $kind." -ForegroundColor Red
        return
    }

    $table = $Presets[$vendor][$kind][$ProfileKey]
    foreach ($kw in $table.Keys) {
        $val = $table[$kw][0]
        $cmt = $table[$kw][1]
        Set-Prop $Adapter.Name $kw $val $cmt
    }
}

# ---------------------------------------------------------------------
# Пошук активного адаптера (для авто-режиму)
# ---------------------------------------------------------------------
function Get-ActiveAdapter {
    $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Sort-Object -Property RouteMetric | Select-Object -First 1

    $adapter = $null
    if ($defaultRoute) {
        $adapter = Get-NetAdapter | Where-Object {
            $_.ifIndex -eq $defaultRoute.ifIndex -and $_.Status -eq 'Up'
        } | Select-Object -First 1
    }
    if (-not $adapter) {
        $adapter = Get-NetAdapter | Where-Object {
            $_.Status -eq 'Up' -and $_.Virtual -eq $false
        } | Sort-Object -Property @{Expression = { $_.InterfaceMetric } } | Select-Object -First 1
    }
    return $adapter
}

function Get-AllPhysicalAdapters {
    Get-NetAdapter | Where-Object { $_.Virtual -eq $false } | Sort-Object Name
}

# ---------------------------------------------------------------------
# Вибір профілю
# ---------------------------------------------------------------------
function Choose-Profile {
    Write-Head "Виберіть пресет"
    Write-Host "  1) " -ForegroundColor White -NoNewline
    Write-Host "Домашній ноутбук" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline
    Write-Host "Робочий ноутбук" -ForegroundColor Gray
    Write-Host "  3) " -ForegroundColor White -NoNewline
    Write-Host "Домашній ПК" -ForegroundColor Gray
    Write-Host "  4) " -ForegroundColor White -NoNewline
    Write-Host "Ігровий ПК/ноутбук" -ForegroundColor Gray
    Write-Host "  0) " -ForegroundColor White -NoNewline
    Write-Host "Назад" -ForegroundColor DarkGray
    $c = Read-Host "`nВаш вибір"
    if ($c -eq "0") { return $null }
    if (-not $ProfileNames.ContainsKey($c)) {
        Write-Host "Невірний вибір." -ForegroundColor Red
        return Choose-Profile
    }
    return $ProfileNames[$c]
}

# ---------------------------------------------------------------------
# Головне меню
# ---------------------------------------------------------------------
Write-Banner

:main while ($true) {
    Write-Head "Головне меню"
    Write-Host "  1) " -ForegroundColor White -NoNewline
    Write-Host "Авто-визначення активного адаптера" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline
    Write-Host "Ручний вибір адаптера" -ForegroundColor Gray
    Write-Host "  3) " -ForegroundColor White -NoNewline
    Write-Host "Застосувати одразу і на Ethernet, і на Wi-Fi" -ForegroundColor Gray
    Write-Host "  0) " -ForegroundColor White -NoNewline
    Write-Host "Вихід" -ForegroundColor DarkGray
    $mode = Read-Host "`nВаш вибір"

    if ($mode -eq "0") { exit }

    $applied = $false

    switch ($mode) {

        "1" {
            Write-Head "Пошук активного адаптера"
            $adapter = Get-ActiveAdapter
            if (-not $adapter) {
                Write-Host "  Активний адаптер не знайдено." -ForegroundColor Red
                continue main
            }
            Show-AdapterCard $adapter

            $profileKey = Choose-Profile
            if (-not $profileKey) { continue main }
            Apply-Preset $adapter $profileKey
            $applied = $true
        }

        "2" {
            $all = @(Get-AllPhysicalAdapters)
            if ($all.Count -eq 0) {
                Write-Host "Адаптери не знайдено." -ForegroundColor Red
                continue main
            }
            Write-Head "Доступні адаптери"
            for ($i = 0; $i -lt $all.Count; $i++) {
                $a = $all[$i]
                $k = Get-AdapterKind $a
                $v = Get-AdapterVendor $a
                $kColor = if ($k -eq "WiFi") { "Magenta" } else { "Blue" }
                $vColor = if ($v -eq "Intel") { "Cyan" } elseif ($v -eq "Realtek") { "Yellow" } else { "Red" }
                $sColor = if ($a.Status -eq "Up") { "Green" } else { "DarkGray" }

                Write-Host ("  {0}) " -f ($i+1)) -ForegroundColor White -NoNewline
                Write-Host ("{0,-28}" -f $a.Name) -ForegroundColor White -NoNewline
                Write-Host " [" -ForegroundColor DarkGray -NoNewline
                Write-Host $v -ForegroundColor $vColor -NoNewline
                Write-Host " " -NoNewline
                Write-Host $k -ForegroundColor $kColor -NoNewline
                Write-Host "]  " -ForegroundColor DarkGray -NoNewline
                Write-Host $a.Status -ForegroundColor $sColor
            }
            Write-Host "  0) " -ForegroundColor White -NoNewline
            Write-Host "Назад" -ForegroundColor DarkGray
            $sel = Read-Host "`nНомер адаптера"
            if ($sel -eq "0" -or -not $sel) { continue main }
            $idx = [int]$sel - 1
            if ($idx -lt 0 -or $idx -ge $all.Count) {
                Write-Host "Невірний номер." -ForegroundColor Red
                continue main
            }
            $adapter = $all[$idx]
            Show-AdapterCard $adapter

            $profileKey = Choose-Profile
            if (-not $profileKey) { continue main }
            Apply-Preset $adapter $profileKey
            $applied = $true
        }

        "3" {
            $all = @(Get-AllPhysicalAdapters)
            $ethAdapters  = @($all | Where-Object { (Get-AdapterKind $_) -eq "Ethernet" })
            $wifiAdapters = @($all | Where-Object { (Get-AdapterKind $_) -eq "WiFi" })

            if ($ethAdapters.Count -eq 0 -and $wifiAdapters.Count -eq 0) {
                Write-Host "Не знайдено ні Ethernet, ні Wi-Fi адаптерів." -ForegroundColor Red
                continue main
            }

            Write-Head "Знайдені адаптери для одночасного налаштування"
            foreach ($a in $ethAdapters)  { Show-AdapterCard $a }
            foreach ($a in $wifiAdapters) { Show-AdapterCard $a }

            $profileKey = Choose-Profile
            if (-not $profileKey) { continue main }

            foreach ($a in $ethAdapters)  { Apply-Preset $a $profileKey }
            foreach ($a in $wifiAdapters) { Apply-Preset $a $profileKey }
            $applied = $true
        }

        default {
            Write-Host "Невірний вибір." -ForegroundColor Red
            continue main
        }
    }

    if ($applied) {
        Write-Head "Готово"
        Write-Host "  Перевірити застосовані значення можна командою:" -ForegroundColor Gray
        Write-Host '  Get-NetAdapterAdvancedProperty -Name "<Ім''я адаптера>" | Format-Table DisplayName,RegistryKeyword,RegistryValue -AutoSize' -ForegroundColor DarkYellow
        Write-Host ""
        Write-Host "  Натисніть будь-яку клавішу, щоб повернутись до меню..." -ForegroundColor Cyan
        $null = [System.Console]::ReadKey($true)
    }
}
