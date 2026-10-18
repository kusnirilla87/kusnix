#requires -RunAsAdministrator
# =====================================================================
#  NetAdapterPreset.ps1
#  Auto-detects wired/Wi-Fi + Intel/Realtek and applies presets of
#  advanced properties (Advanced Properties).
#
#  Profiles:  1) Home (laptop or PC, plugged in)   2) Work laptop
#             3) Gaming PC/laptop (low ping)       4) Maximum battery life
#             5) Maximum speed (throughput)
#
#  Modes:
#    A) Auto   - detects the active adapter and its type by itself
#    B) Manual - shows a list of all adapters, you pick the one you need
#    C) Both   - applies the preset to Ethernet and Wi-Fi at the same time
#    D) DNS    - benchmarks the servers from DnsJumper.ini (like DNS Jumper)
#                and applies the fastest one (or the one you choose)
#
#  What every preset run does:
#    * per-adapter Advanced Properties of the chosen profile (validated
#      against the values the driver really accepts)
#    * global NETWORK-TWEAKS (RSC on, packet coalescing filter off)
#    * Home        : adapter advanced properties reset to driver defaults, then
#                     every power-saving option switched OFF (mains power assumed)
#    * Work laptop  : every power-saving option enabled
#    * Gaming PC    : low ping + OPTIMIZE-NETWORKING.reg (applied to the REAL adapter
#                     key, not to a hard-coded \0002) and the global NDIS tweaks
#    * Max battery : Work laptop + wake-ups off, lowest TX power, fewer RSS queues
#    * Max speed   : power saving off, widest channels, max TX power, max buffers/RSS
#    Special values in the tables: @LOW / @HIGH (by driver display name),
#    @MAXNUM (largest value the driver allows), @WIDEST (widest channel width)
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
    Write-Host "   Intel / Realtek  •  Ethernet / Wi-Fi  •  Advanced Properties  •  DNS" -ForegroundColor DarkGray
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
# Helper function for applying a property
# ---------------------------------------------------------------------
function Write-Status {
    param([string]$Tag, [string]$Color, [string]$Text, [string]$Comment = "")
    Write-Host "   [" -ForegroundColor DarkGray -NoNewline
    Write-Host $Tag -ForegroundColor $Color -NoNewline
    Write-Host "] " -ForegroundColor DarkGray -NoNewline
    Write-Host $Text -ForegroundColor White -NoNewline
    if ($Comment) { Write-Host ("  " + $Comment) -ForegroundColor DarkGray } else { Write-Host "" }
}

function Resolve-SpecialValue {
    # @LOW / @HIGH : pick by the driver's display name   @MAXNUM : largest allowed number   @WIDEST : widest MHz
    param($Prop, [string]$Token)
    $regs = @($Prop.ValidRegistryValues)
    $disp = @($Prop.ValidDisplayValues)

    if ($Token -eq "@MAXNUM") {
        $nums = @($regs | ForEach-Object { $n = 0L; if ([long]::TryParse($_, [ref]$n)) { $n } })
        if ($nums.Count -gt 0) { return [string](($nums | Measure-Object -Maximum).Maximum) }
        if ($null -ne $Prop.NumericParameterMaxValue) { return [string]$Prop.NumericParameterMaxValue }
        return $null
    }
    if ($regs.Count -eq 0 -or $regs.Count -ne $disp.Count) { return $null }

    if ($Token -eq "@WIDEST") {
        $best = -1; $val = $null
        for ($k = 0; $k -lt $disp.Count; $k++) {
            if ($disp[$k] -match '(\d+)\s*MHz') {
                $w = [int]$Matches[1]
                if ($w -gt $best) { $best = $w; $val = $regs[$k] }
            }
        }
        return $val
    }

    $patterns = if ($Token -eq "@LOW") { @('(?i)lowest|minimum|\bmin\b', '(?i)^low$') }
                elseif ($Token -eq "@HIGH") { @('(?i)highest|maximum|\bmax\b', '(?i)^high$') }
                else { @() }
    foreach ($rx in $patterns) {
        for ($k = 0; $k -lt $disp.Count; $k++) { if ($disp[$k] -match $rx) { return $regs[$k] } }
    }
    return $null
}

function Write-Status {
    param([string]$Tag, [string]$Color, [string]$Text, [string]$Comment = "")
    Write-Host "   [" -ForegroundColor DarkGray -NoNewline
    Write-Host $Tag -ForegroundColor $Color -NoNewline
    Write-Host "] " -ForegroundColor DarkGray -NoNewline
    Write-Host $Text -ForegroundColor White -NoNewline
    if ($Comment) { Write-Host ("  " + $Comment) -ForegroundColor DarkGray } else { Write-Host "" }
}

function Set-Prop {
    param(
        [string]$Adapter,
        [string]$Keyword,
        [string]$Value,
        [string]$Comment = ""
    )
    $prop = Get-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -ErrorAction SilentlyContinue
    if (-not $prop) {
        Write-Status "SKIP" "Yellow" ("{0,-28} (property not present on this adapter)" -f $Keyword)
        return
    }
    if ($Value.StartsWith("@")) {
        $token = $Value
        $resolved = Resolve-SpecialValue $prop $token
        if ($null -eq $resolved) {
            Write-Status "SKIP" "Yellow" ("{0,-28} driver has no value for {1}" -f $Keyword, $token)
            return
        }
        $regs = @($prop.ValidRegistryValues); $disp = @($prop.ValidDisplayValues)
        $idx  = [array]::IndexOf($regs, [string]$resolved)
        $dn   = if ($idx -ge 0 -and $disp.Count -eq $regs.Count) { $disp[$idx] } else { "" }
        $Comment = ("{0} [{1} -> {2}]" -f $Comment, $token, $dn).Trim()
        $Value = [string]$resolved
    }
    $valid = @($prop.ValidRegistryValues)
    if ($valid.Count -gt 0 -and ($valid -notcontains $Value)) {
        Write-Status "SKIP" "Yellow" ("{0,-28} value {1} not accepted by driver" -f $Keyword, $Value) ("(valid: " + ($valid -join ",") + ")")
        return
    }
    try {
        Set-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -RegistryValue $Value -NoRestart -ErrorAction Stop
        Write-Status "OK  " "Green" ("{0,-28} -> {1,-6}" -f $Keyword, $Value) $Comment
    } catch {
        Write-Status "FAIL" "Red" ("{0,-28} {1}" -f $Keyword, $_.Exception.Message)
    }
}

# ---------------------------------------------------------------------
# Detect type (Ethernet/Wi-Fi) and vendor (Intel/Realtek)
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
# Adapter registry path (network adapter class)
# ---------------------------------------------------------------------
$script:ClassRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'

function Get-AdapterRegistryPath {
    # Returns e.g. HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36...}\0007
    param($Adapter)
    foreach ($k in (Get-ChildItem $script:ClassRoot -ErrorAction SilentlyContinue)) {
        $id = (Get-ItemProperty -LiteralPath $k.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue).NetCfgInstanceId
        if ($id -and $id -eq $Adapter.InterfaceGuid) { return $k.Name }
    }
    return $null
}

# ---------------------------------------------------------------------
# Detect driver type: NDIS (legacy) or NetAdapterCx (modern)
# Logic from CHECK-NIC-DRIVER-TYPE.ps1
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
# Nice info card for the found/selected adapter
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
    Write-Host "ADAPTER FOUND" -ForegroundColor White -NoNewline
    Write-Host (" " * 49) -NoNewline
    Write-Host "┃" -ForegroundColor DarkGray
    Write-Host "  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫" -ForegroundColor DarkGray

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Name        : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.Name -ForegroundColor White

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Description : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.InterfaceDescription -ForegroundColor DarkCyan

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Status      : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.Status -ForegroundColor $statusColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Link type   : " -ForegroundColor Gray -NoNewline
    Write-Host $kind -ForegroundColor $kindColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Vendor      : " -ForegroundColor Gray -NoNewline
    Write-Host $vendor -ForegroundColor $vendorColor

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Driver type : " -ForegroundColor Gray -NoNewline
    Write-Host $driverType -ForegroundColor $drvColor -NoNewline
    if ($driverType -eq "NetAdapterCx") {
        Write-Host "  (modern, full Advanced Properties support)" -ForegroundColor DarkGray
    } elseif ($driverType -eq "NDIS") {
        Write-Host "  (classic NDIS driver)" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Speed       : " -ForegroundColor Gray -NoNewline
    Write-Host $Adapter.LinkSpeed -ForegroundColor White

    Write-Host "  ┃ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Registry    : " -ForegroundColor Gray -NoNewline
    if ($regPath) {
        Write-Host $regPath -ForegroundColor DarkYellow
    } else {
        Write-Host "could not be determined" -ForegroundColor DarkGray
    }

    Write-Host "  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# PRESETS. Structure: $Presets[Vendor][Kind][Profile] = @{ Keyword=Value }
# Profiles: Home, WorkLaptop, GamePC, MaxBattery, MaxSpeed
# Comments correspond to the collected tables (intel/realtek eth/wifi).
# ---------------------------------------------------------------------

$Presets = @{}

# ===================== INTEL ETHERNET =====================
$Presets.Intel = @{}
$Presets.Intel.Ethernet = @{
    Home = @{
        # plugged in: every power-saving option OFF. Everything else stays at driver default
        # (the script resets all advanced properties first).
        "ReduceSpeedOnPowerDown"  = @("0","Disabled")
        "SIPS"                    = @("0","Disabled")
        "SmartPowerDownEnable"    = @("0","Disabled")
        "*EEE"                    = @("0","Disabled")
        "EEELinkAdvertisement"    = @("0","Disabled")
        "EnableGreenEthernet"     = @("0","Disabled")
        "GigaLite"                = @("0","Disabled")
        "ULPMode"                 = @("0","Disabled")
        "AutoPowerSaveModeEnabled"= @("0","Disabled")
        "PME"                     = @("0","Disabled")
        "EnablePME"               = @("0","Disabled")
    }
    WorkLaptop = @{
        # ALL power-saving options enabled (unknown keywords are skipped automatically)
        "ReduceSpeedOnPowerDown"  = @("1","Enabled (power saving)")
        "SIPS"                    = @("1","System Idle Power Saver Enabled")
        "SmartPowerDownEnable"    = @("1","Link speed battery saver Enabled")
        "*EEE"                    = @("1","Energy Efficient Ethernet Enabled")
        "EEELinkAdvertisement"    = @("1","EEE link advertisement Enabled")
        "EnableGreenEthernet"     = @("1","Green Ethernet Enabled")
        "GigaLite"                = @("1","Gigabit Lite Enabled")
        "ULPMode"                 = @("1","Ultra Low Power mode Enabled")
        "AutoPowerSaveModeEnabled"= @("1","Auto power save Enabled")
        "PME"                     = @("1","Enable PME Enabled")
        "EnablePME"               = @("1","Enable PME Enabled")
        "*FlowControl"            = @("3","Enabled")
        "*InterruptModeration"    = @("1","Enabled")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 1/2")
    }
    MaxBattery = @{
        "ReduceSpeedOnPowerDown"  = @("1","Enabled")
        "SIPS"                    = @("1","System Idle Power Saver Enabled")
        "SmartPowerDownEnable"    = @("1","Enabled")
        "*EEE"                    = @("1","Energy Efficient Ethernet Enabled")
        "EEELinkAdvertisement"    = @("1","Enabled")
        "EnableGreenEthernet"     = @("1","Enabled")
        "GigaLite"                = @("1","Enabled")
        "ULPMode"                 = @("1","Enabled")
        "AutoPowerSaveModeEnabled"= @("1","Enabled")
        "PME"                     = @("1","Enabled")
        "EnablePME"               = @("1","Enabled")
        "*WakeOnMagicPacket"      = @("0","Wake-ups off (saves power)")
        "*WakeOnPattern"          = @("0","Wake-ups off (saves power)")
        "WakeOnLink"              = @("0","Wake-ups off (saves power)")
        "*InterruptModeration"    = @("1","Enabled (fewer CPU wake-ups)")
        "ITR"                     = @("65535","Adaptive")
        "*NumRssQueues"           = @("1","1 RSS queue (fewer cores woken)")
    }
    MaxSpeed = @{
        "ReduceSpeedOnPowerDown"  = @("0","Disabled")
        "SIPS"                    = @("0","Disabled")
        "SmartPowerDownEnable"    = @("0","Disabled")
        "*EEE"                    = @("0","Disabled")
        "EnableGreenEthernet"     = @("0","Disabled")
        "GigaLite"                = @("0","Disabled")
        "ULPMode"                 = @("0","Disabled")
        "AutoPowerSaveModeEnabled"= @("0","Disabled")
        "PME"                     = @("0","Disabled")
        "*FlowControl"            = @("3","Rx & Tx (no drops on sustained transfers)")
        "*InterruptModeration"    = @("1","Enabled (best throughput / CPU)")
        "ITR"                     = @("65535","Adaptive")
        "*NumRssQueues"           = @("@MAXNUM","max RSS queues")
        "*ReceiveBuffers"         = @("@MAXNUM","max receive buffers")
        "*TransmitBuffers"        = @("@MAXNUM","max transmit buffers")
        "*IPChecksumOffloadIPv4"  = @("3","Rx & Tx")
        "*TCPChecksumOffloadIPv4" = @("3","Rx & Tx")
        "*TCPChecksumOffloadIPv6" = @("3","Rx & Tx")
        "*UDPChecksumOffloadIPv4" = @("3","Rx & Tx")
        "*UDPChecksumOffloadIPv6" = @("3","Rx & Tx")
        "*LsoV2IPv4"              = @("1","Enabled")
        "*LsoV2IPv6"              = @("1","Enabled")
        "*RscIPv4"                = @("1","Enabled")
        "*RscIPv6"                = @("1","Enabled")
        "*UsoIPv4"                = @("1","Enabled")
        "*UsoIPv6"                = @("1","Enabled")
    }
    GamePC = @{
        "ReduceSpeedOnPowerDown"  = @("0","Disabled")
        "SIPS"                    = @("0","Disabled")
        "SmartPowerDownEnable"    = @("0","Disabled")
        "*EEE"                    = @("0","Disabled")
        "PME"                     = @("0","Disabled")
        "*FlowControl"            = @("0","Disabled (min. jitter)")
        "*InterruptModeration"    = @("0","Disabled (min. latency)")
        "ITR"                     = @("0","Interrupt moderation rate Disable")
        "*RssBaseProcNumber"      = @("0","Maximum RSS queues 2/4")
    }
}

# ===================== INTEL WI-FI =====================
$Presets.Intel.WiFi = @{
    Home = @{
        "UAPSDSupport"             = @("0","Disabled")
        "MimoPowerSaveMode"        = @("0","No SMPS")
        "IbssTxPower"              = @("@HIGH","Maximum TX power")
        "PacketCoalescing"         = @("0","Disabled")
        "SleepModeWoWLAN"          = @("0","Disabled")
        "*DeviceSleepOnDisconnect" = @("0","Disabled")
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
        # extra power-saving options
        "*DeviceSleepOnDisconnect" = @("1","Device sleep on disconnect Enabled")
        "*PMARPOffload"            = @("1","ARP offload Enabled")
        "*PMNSOffload"             = @("1","NS offload Enabled")
        "*PMWiFiRekeyOffload"      = @("1","Re-key offload Enabled")
    }
    MaxBattery = @{
        "UAPSDSupport"             = @("1","U-APSD Enabled")
        "ThroughputBooster"        = @("0","Disable")
        "RoamingPreferredBandType" = @("0","None")
        "RoamAggressiveness"       = @("1","Low (fewer scans)")
        "MimoPowerSaveMode"        = @("1","Auto SMPS")
        "IbssTxPower"              = @("@LOW","Lowest TX power")
        "FatChannelIntolerant"     = @("1","Enable")
        "ChannelWidth24"           = @("0","20MHz")
        "ChannelWidth52"           = @("2","80MHz (finish transfers fast, then idle)")
        "CtsToItself"              = @("1","CTS-to-Self (less overhead)")
        "PacketCoalescing"         = @("1","Enabled")
        "SleepModeWoWLAN"          = @("1","Enabled")
        "*DeviceSleepOnDisconnect" = @("1","Enabled")
        "*PMARPOffload"            = @("1","ARP offload Enabled")
        "*PMNSOffload"             = @("1","NS offload Enabled")
        "*PMWiFiRekeyOffload"      = @("1","Re-key offload Enabled")
        "*WakeOnMagicPacket"       = @("0","Wake-ups off")
        "*WakeOnPattern"           = @("0","Wake-ups off")
    }
    MaxSpeed = @{
        "UAPSDSupport"             = @("0","Disabled")
        "ThroughputBooster"        = @("1","Enable")
        "RoamingPreferredBandType" = @("2","5GHz")
        "RoamAggressiveness"       = @("2","Medium")
        "MimoPowerSaveMode"        = @("0","No SMPS")
        "IbssTxPower"              = @("@HIGH","Maximum TX power")
        "FatChannelIntolerant"     = @("0","Disable")
        "ChannelWidth24"           = @("1","40MHz")
        "ChannelWidth52"           = @("@WIDEST","widest channel (160MHz if supported)")
        "CtsToItself"              = @("1","CTS-to-Self")
        "PacketCoalescing"         = @("0","Disabled")
        "SleepModeWoWLAN"          = @("0","Disabled")
        "*DeviceSleepOnDisconnect" = @("0","Disabled")
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
# Keys and values verified against the real registry dump (Ndi\params) of the user's
# Realtek PCIe GbE Family Controller card - 100% match.
$Presets.Realtek = @{}
$Presets.Realtek.Ethernet = @{
    Home = @{
        # power-saving OFF only; everything else = driver default
        "*EEE"                = @("0","Disabled")
        "AdvancedEEE"         = @("0","Disabled")
        "EnableGreenEthernet" = @("0","Disabled")
        "GigaLite"            = @("0","Disabled")
        "PowerSavingMode"     = @("0","Disabled")
        "AutoDisableGigabit"  = @("0","Disabled")
    }
    WorkLaptop = @{
        "*FlowControl"              = @("3","Rx & Tx Enabled")
        "*InterruptModeration"      = @("1","Enabled")
        "*NumRssQueues"             = @("1","1 Queue")
    }
    MaxBattery = @{
        "*InterruptModeration"      = @("1","Enabled (fewer CPU wake-ups)")
        "*NumRssQueues"             = @("1","1 Queue")
    }
    MaxSpeed = @{
        "*FlowControl"              = @("3","Rx & Tx Enabled")
        "*InterruptModeration"      = @("1","Enabled (best throughput / CPU)")
        "*NumRssQueues"             = @("@MAXNUM","max RSS queues")
        "*ReceiveBuffers"           = @("@MAXNUM","max receive buffers")
        "*TransmitBuffers"          = @("@MAXNUM","max transmit buffers")
        "*RscIPv4"                  = @("1","Enabled")
        "*RscIPv6"                  = @("1","Enabled")
        "*UsoIPv4"                  = @("1","Enabled")
        "*UsoIPv6"                  = @("1","Enabled")
    }
    GamePC = @{
        "*FlowControl"              = @("0","Disabled (min. jitter)")
        "*InterruptModeration"      = @("0","Disabled (min. latency)")
        "*NumRssQueues"             = @("4","4 Queues")
    }
}
# Realtek Ethernet values shared by every profile except Home (Home = driver defaults)
# (taken 1:1 from your realtekETHERNEt.txt - those lines have no per-column split):
foreach ($p in @("WorkLaptop","GamePC","MaxBattery","MaxSpeed")) {
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
    $Presets.Realtek.Ethernet[$p]["*JumboPacket"]            = @("1514","Disabled (no jumbo frames)")
    $Presets.Realtek.Ethernet[$p]["*IPChecksumOffloadIPv4"]  = @("3","Rx & Tx Enabled")
}
# Work laptop + Max battery: ALL Realtek power-saving options enabled (override of the shared "0" values above)
foreach ($p in @("WorkLaptop","MaxBattery")) {
    $Presets.Realtek.Ethernet[$p]["*EEE"]                = @("1","Energy Efficient Ethernet Enabled")
    $Presets.Realtek.Ethernet[$p]["AdvancedEEE"]         = @("1","Advanced EEE Enabled")
    $Presets.Realtek.Ethernet[$p]["EnableGreenEthernet"] = @("1","Green Ethernet Enabled")
    $Presets.Realtek.Ethernet[$p]["GigaLite"]            = @("1","Giga Lite Enabled")
    $Presets.Realtek.Ethernet[$p]["PowerSavingMode"]     = @("1","Power Saving Mode Enabled")
    $Presets.Realtek.Ethernet[$p]["AutoDisableGigabit"]  = @("1","Auto Disable Gigabit Enabled")
}

# ===================== REALTEK WI-FI =====================
# Keys and values verified against the real registry dump (Ndi\params) of the user's
# Realtek RTL8822CE 802.11ac PCIe Adapter card - 100% match.
# Important: WakeOnDisconnect has an INVERTED enum (0=Enabled, 1=Disabled)!
$Presets.Realtek.WiFi = @{
    Home = @{
        "WakeOnDisconnect"     = @("1","Sleep on WoWLAN disconnect: Disabled")
        "TxPwrLevel"           = @("@HIGH","Highest TX power")
    }
    WorkLaptop = @{
        "WakeOnDisconnect"     = @("0","Sleep on WoWLAN disconnect: Enabled")
        "RegROAMSensitiveLevel"= @("70","Roaming Aggressiveness: Medium-High")
        "PreferBand"           = @("0","Preferred Band: No Preference")
        "ProtectionMode"       = @("0","RTS/CTS Enabled")
        "b40Intolerant"        = @("1","Fat Channel Intolerant: Enabled")
        "BW40MHzFor2G"         = @("0","2.4GHz: 20MHz Only")
    }
    MaxBattery = @{
        "WakeOnDisconnect"     = @("0","Sleep on WoWLAN disconnect: Enabled")
        "RegROAMSensitiveLevel"= @("85","Roaming Aggressiveness: Lowest (fewer scans)")
        "PreferBand"           = @("0","Preferred Band: No Preference")
        "ProtectionMode"       = @("1","CTS-to-self Enabled")
        "b40Intolerant"        = @("1","Fat Channel Intolerant: Enabled")
        "BW40MHzFor2G"         = @("0","2.4GHz: 20MHz Only")
    }
    MaxSpeed = @{
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
# Realtek Wi-Fi values shared by every profile except Home (Home = driver defaults)
# (taken 1:1 from your realtekWIFI.txt - lines with no per-column split):
foreach ($p in @("WorkLaptop","GamePC","MaxBattery","MaxSpeed")) {
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
# Max battery: lowest TX power (picked by display name; skipped if the driver has no such entry)
$Presets.Realtek.WiFi.MaxBattery["TxPwrLevel"] = @("@LOW","Lowest TX power")

$ProfileNames = @{
    "1" = "Home"
    "2" = "WorkLaptop"
    "3" = "GamePC"
    "4" = "MaxBattery"
    "5" = "MaxSpeed"
}
$ProfileLabels = @{
    "Home"       = "Home (power saving OFF, rest default)"
    "WorkLaptop" = "Work laptop (power saving ON)"
    "GamePC"     = "Gaming PC/laptop (low ping)"
    "MaxBattery" = "Maximum battery life"
    "MaxSpeed"   = "Maximum speed (throughput)"
}

# ---------------------------------------------------------------------
# Windows-level power management per profile
# (Device Manager -> adapter -> Power Management + power plan)
# ---------------------------------------------------------------------
$PmProfiles = @{
    WorkLaptop = @{
        Props = [ordered]@{
            ArpOffload              = "Enabled"
            NSOffload               = "Enabled"
            RsnRekeyOffload         = "Enabled"
            D0PacketCoalescing      = "Enabled"
            DeviceSleepOnDisconnect = "Enabled"
            SelectiveSuspend        = "Enabled"
        }
        AllowPowerOff = $true      # "Allow the computer to turn off this device to save power"
        WifiPlanMode  = 3          # power plan -> Wireless Adapter Settings -> Maximum Power Saving
    }
    Home = @{
        Props = [ordered]@{
            D0PacketCoalescing      = "Disabled"
            DeviceSleepOnDisconnect = "Disabled"
            SelectiveSuspend        = "Disabled"
        }
        AllowPowerOff = $false     # "Allow the computer to turn off this device" -> OFF
        WifiPlanMode  = 0          # power plan -> Wireless Adapter Settings -> Maximum Performance
    }
    MaxBattery = @{
        Props = [ordered]@{
            ArpOffload              = "Enabled"
            NSOffload               = "Enabled"
            RsnRekeyOffload         = "Enabled"
            D0PacketCoalescing      = "Enabled"
            DeviceSleepOnDisconnect = "Enabled"
            SelectiveSuspend        = "Enabled"
            WakeOnMagicPacket       = "Disabled"
            WakeOnPattern           = "Disabled"
        }
        AllowPowerOff = $true
        WifiPlanMode  = 3
    }
    MaxSpeed = @{
        Props = [ordered]@{
            D0PacketCoalescing      = "Disabled"
            DeviceSleepOnDisconnect = "Disabled"
            SelectiveSuspend        = "Disabled"
        }
        AllowPowerOff = $false
        WifiPlanMode  = 0
    }
}

# ---------------------------------------------------------------------
# OPTIMIZE-NETWORKING.reg  (Gaming PC)
# The .reg wrote to a hard-coded ...\Class\{4D36E972...}\0002 - which is a
# random adapter on most PCs. Here the same values go to the key of the
# adapter that was actually selected, and only if the driver accepts them.
# ---------------------------------------------------------------------
$RegForceAll = $false   # $true = write EVERY value even if the driver does not expose it (like importing the .reg blindly)

$GameRegValues = [ordered]@{
    "*EncapsulatedPacketTaskOffloadNvgre" = "1"
    "*EncapsulatedPacketTaskOffloadVxlan" = "1"
    "*EncapsulatedPacketTaskOffload"      = "1"
    "*IPChecksumOffloadIPv4"              = "3"
    "*LsoV1IPv4"                          = "1"
    "*LsoV2IPv4"                          = "1"
    "*LsoV2IPv6"                          = "1"
    "*TCPChecksumOffloadIPv4"             = "3"
    "*TCPChecksumOffloadIPv6"             = "3"
    "*UDPChecksumOffloadIPv4"             = "3"
    "*UDPChecksumOffloadIPv6"             = "3"
    "*IPsecOffloadV1IPv4"                 = "3"
    "*IPsecOffloadV2"                     = "3"
    "*IPsecOffloadV2IPv4"                 = "3"
    "*TCPConnectionOffloadIPv4"           = "1"
    "*TCPConnectionOffloadIPv6"           = "1"
    "*TCPUDPChecksumOffloadIPv4"          = "3"
    "*TCPUDPChecksumOffloadIPv6"          = "3"
    "*UsoIPv4"                            = "1"
    "*UsoIPv6"                            = "1"
    "TeredoOffload"                       = "1"
    "*QoSOffload"                         = "1"
    "*Rss"                                = "1"
    "*NumRssQueues"                       = "1"
    "RssV2"                               = "1"
    "*VMQ"                                = "0"
    "VMQSupported"                        = "0"
    "*FlowControl"                        = "0"
    "FecMode"                             = "0"
    "*RscIPv4"                            = "1"
    "*RscIPv6"                            = "1"
    "ForceRscEnabled"                     = "1"
    "*UdpRsc"                             = "1"
    "*InterruptModeration"                = "0"
    "TxIntModeration"                     = "0"
    "RxIntModeration"                     = "0"
    "*JumboPacket"                        = "1510"
    "DisableLLDP"                         = "1"
    "*HeaderDataSplit"                    = "1"
    "HDSplitAlways"                       = "1"
    "*ReceiveBuffers"                     = "4096"
    "StoreBadPackets"                     = "0"
    "RecvCompletionMethod"                = "4"
    "AsyncReceiveIndicate"                = "2"
    "ThreadedDpcEnable"                   = "0"
    "*TransmitBuffers"                    = "4096"
    "DropHighlyFragmentedPacket"          = "1"
    "EnableCoalesce"                      = "0"
    "TxThreadedDpcEnable"                 = "0"
    "SendCompletionMethod"                = "2"
    "ThreadPoll"                          = "200000"
    "*PacketCoalescing"                   = "0"
    "*PacketDirect"                       = "1"
    "*NdisPoll"                           = "1"
    "*NetworkDirect"                      = "0"
    "CongestionMonitoringEnable"          = "0"   # the .reg name had 7 invisible zero-width chars appended; removed here
    "*SRIOV"                              = "0"
}

# [HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters]  (global, DWORD)
$GameNdisValues = [ordered]@{
    "DisableNDISWatchDog"                 = 1
    "DisableNaps"                         = 1
    "NoPauseOnSuspend"                    = 1
    "DebugLoggingMode"                    = 0
    "DisableWDIWatchdogForceBugcheck"     = 1
    "DisableReenumerationTimeoutBugcheck" = 1
    "EnableNicAutoPowerSaverInSleepStudy" = 0
}

function Test-DriverParam {
    # 'ok' | 'invalid' (driver knows the keyword but not this value) | 'unsupported'
    param($Key, [string]$Keyword, [string]$Value)
    $pk = $Key.OpenSubKey("Ndi\params\$Keyword")
    if ($pk) {
        $type = [string]$pk.GetValue('type')
        if ($type -eq 'enum') {
            $ek = $pk.OpenSubKey('enum')
            if ($ek) { if (@($ek.GetValueNames()) -contains $Value) { return 'ok' } else { return 'invalid' } }
            return 'ok'
        }
        if ($type -in @('int','long','dword')) {
            $n = 0
            if (-not [int]::TryParse($Value, [ref]$n)) { return 'invalid' }
            try {
                $min = $pk.GetValue('min'); $max = $pk.GetValue('max')
                if ($null -ne $min -and $n -lt [int]$min) { return 'invalid' }
                if ($null -ne $max -and $n -gt [int]$max) { return 'invalid' }
            } catch {}
            return 'ok'
        }
        return 'ok'
    }
    if ($null -ne $Key.GetValue($Keyword)) { return 'ok' }      # hidden value already used by the driver
    if ($RegForceAll) { return 'ok' }
    return 'unsupported'
}

function Set-KeyValueSmart {
    # keeps the existing value type (REG_DWORD stays REG_DWORD), otherwise REG_SZ like the .reg did
    param($Key, [string]$Name, [string]$Value)
    $kind = 'String'
    if ($null -ne $Key.GetValue($Name)) { $kind = [string]$Key.GetValueKind($Name) }
    if ($kind -eq 'DWord') { $Key.SetValue($Name, [int]$Value, [Microsoft.Win32.RegistryValueKind]::DWord) }
    else                   { $Key.SetValue($Name, [string]$Value, [Microsoft.Win32.RegistryValueKind]::String) }
}

function Open-AdapterKey {
    param($Adapter)
    $path = Get-AdapterRegistryPath $Adapter
    if (-not $path) { return $null }
    $sub = $path -replace '^HKEY_LOCAL_MACHINE\\', ''
    return [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($sub, $true)
}

function Apply-GameRegTweaks {
    param($Adapter, $PresetTable)
    Write-Sub "OPTIMIZE-NETWORKING.reg -> adapter registry key" Cyan
    $key = Open-AdapterKey $Adapter
    if (-not $key) {
        Write-Status "FAIL" "Red" "adapter registry key not found - reg tweaks skipped"
        return
    }
    foreach ($kw in $GameRegValues.Keys) {
        $val = [string]$GameRegValues[$kw]
        $st = Test-DriverParam $key $kw $val
        if ($st -eq 'unsupported') { Write-Status "SKIP" "Yellow" ("{0,-36} (not exposed by this driver)" -f $kw); continue }
        if ($st -eq 'invalid')     { Write-Status "SKIP" "Yellow" ("{0,-36} value {1} not accepted by driver" -f $kw, $val); continue }
        $cur = $key.GetValue($kw)
        $note = ""
        if ($PresetTable -and $PresetTable.ContainsKey($kw) -and $PresetTable[$kw][0] -ne $val) {
            $note = "(overrides preset value " + $PresetTable[$kw][0] + ")"
        }
        if ($null -ne $cur -and [string]$cur -eq $val) {
            Write-Status "=   " "DarkGray" ("{0,-36} = {1,-8}" -f $kw, $val) "(already set)"
            continue
        }
        try {
            Set-KeyValueSmart $key $kw $val
            Write-Status "OK  " "Green" ("{0,-36} -> {1,-8}" -f $kw, $val) $note
        } catch {
            Write-Status "FAIL" "Red" ("{0,-36} {1}" -f $kw, $_.Exception.Message)
        }
    }
    $key.Close()
}

function Apply-PowerMgmt {
    param($Adapter, [string]$ProfileKey)
    if (-not $PmProfiles.ContainsKey($ProfileKey)) { return }
    $cfg  = $PmProfiles[$ProfileKey]
    $kind = Get-AdapterKind $Adapter
    Write-Sub "Windows power management" Cyan

    $pm = Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction SilentlyContinue
    foreach ($k in $cfg.Props.Keys) {
        $want = $cfg.Props[$k]
        $cur  = if ($pm) { [string]$pm.$k } else { "" }
        if (-not $cur -or $cur -eq "Unsupported") {
            Write-Status "SKIP" "Yellow" ("{0,-26} (unsupported by this adapter)" -f $k)
        } elseif ($cur -eq $want) {
            Write-Status "=   " "DarkGray" ("{0,-26} = {1}" -f $k, $want) "(already set)"
        } else {
            try {
                $splat = @{ Name = $Adapter.Name; NoRestart = $true }
                $splat[$k] = $want
                Set-NetAdapterPowerManagement @splat -ErrorAction Stop
                Write-Status "OK  " "Green" ("{0,-26} -> {1}" -f $k, $want)
            } catch {
                Write-Status "FAIL" "Red" ("{0,-26} {1}" -f $k, $_.Exception.Message)
            }
        }
    }

    if ($null -ne $cfg.AllowPowerOff) {
        $key = Open-AdapterKey $Adapter
        if ($key) {
            try {
                # PnPCapabilities: 0 = "allow the computer to turn off this device" ON, 24 = OFF
                $key.SetValue("PnPCapabilities", $(if ($cfg.AllowPowerOff) { 0 } else { 24 }), [Microsoft.Win32.RegistryValueKind]::DWord)
                Write-Status "OK  " "Green" ("PnPCapabilities              -> Windows {0} turn the device off" -f $(if ($cfg.AllowPowerOff) { "MAY" } else { "may NOT" }))
            } catch { Write-Status "FAIL" "Red" ("PnPCapabilities  " + $_.Exception.Message) }
            $key.Close()
        }
    }

    if ($kind -eq "WiFi" -and $null -ne $cfg.WifiPlanMode) {
        # SUB_WIRELESS = 19cbb8fa-..., POWERSAVING = 12bbebe6-... (0 max performance .. 3 max power saving)
        try {
            & powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a $cfg.WifiPlanMode | Out-Null
            & powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a $cfg.WifiPlanMode | Out-Null
            & powercfg /setactive SCHEME_CURRENT | Out-Null
            Write-Status "OK  " "Green" ("Power plan: Wireless Adapter power saving level {0} (AC + battery; 0 = max performance, 3 = max saving)" -f $cfg.WifiPlanMode)
        } catch { Write-Status "FAIL" "Red" ("powercfg  " + $_.Exception.Message) }
    }
}

# ---------------------------------------------------------------------
# Global tweaks (NETWORK-TWEAKS.ps1 for every profile; NDIS keys for Gaming PC)
# Executed once per run, not once per adapter.
# ---------------------------------------------------------------------
function Apply-GlobalNetTweaks {
    param([string]$ProfileKey)
    Write-Head "Global network tweaks"

    try {
        Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled -ErrorAction Stop
        Write-Status "OK  " "Green" "ReceiveSegmentCoalescing     -> Enabled"
    } catch { Write-Status "FAIL" "Red" ("ReceiveSegmentCoalescing  " + $_.Exception.Message) }
    try {
        Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled -ErrorAction Stop
        Write-Status "OK  " "Green" "PacketCoalescingFilter       -> Disabled"
    } catch { Write-Status "FAIL" "Red" ("PacketCoalescingFilter  " + $_.Exception.Message) }

    if ($ProfileKey -eq "GamePC") {
        try {
            $k = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey('SYSTEM\CurrentControlSet\Services\NDIS\Parameters')
            foreach ($n in $GameNdisValues.Keys) {
                $k.SetValue($n, [int]$GameNdisValues[$n], [Microsoft.Win32.RegistryValueKind]::DWord)
                Write-Status "OK  " "Green" ("NDIS\Parameters\{0,-34} -> {1}" -f $n, $GameNdisValues[$n])
            }
            $k.Close()
            Write-Host "   (NDIS parameters need a reboot to take effect)" -ForegroundColor Yellow
        } catch { Write-Status "FAIL" "Red" ("NDIS\Parameters  " + $_.Exception.Message) }
    }

    $g = Get-NetOffloadGlobalSetting -ErrorAction SilentlyContinue
    if ($g) {
        Write-Sub ("Now: RSC = {0}, PacketCoalescingFilter = {1}" -f $g.ReceiveSegmentCoalescing, $g.PacketCoalescingFilter) DarkGray
    }
}

# ---------------------------------------------------------------------
# Apply a preset to a specific adapter
# ---------------------------------------------------------------------
function Apply-Preset {
    param($Adapter, [string]$ProfileKey)

    $kind   = Get-AdapterKind   $Adapter
    $vendor = Get-AdapterVendor $Adapter

    Write-Head "$($Adapter.Name) [$vendor $kind] -> $($ProfileLabels[$ProfileKey])"

    if ($vendor -eq "Unknown") {
        Write-Host "  Could not determine the vendor (not Intel/Realtek). Skipped." -ForegroundColor Red
        return
    }
    if (-not $Presets.ContainsKey($vendor) -or -not $Presets[$vendor].ContainsKey($kind)) {
        Write-Host "  No preset available for $vendor $kind." -ForegroundColor Red
        return
    }

    if ($ProfileKey -eq "Home") {
        # "everything else = Windows default": reset ALL advanced properties first, then switch power saving off
        try {
            Reset-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName "*" -NoRestart -ErrorAction Stop
            Write-Status "OK  " "Green" "All advanced properties reset to driver defaults"
        } catch {
            Write-Status "FAIL" "Red" ("Reset to defaults: " + $_.Exception.Message)
        }
    }

    $table = $Presets[$vendor][$kind][$ProfileKey]
    foreach ($kw in $table.Keys) {
        $val = $table[$kw][0]
        $cmt = $table[$kw][1]
        Set-Prop $Adapter.Name $kw $val $cmt
    }

    Apply-PowerMgmt $Adapter $ProfileKey
    if ($ProfileKey -eq "GamePC") { Apply-GameRegTweaks $Adapter $table }

    # values were written with -NoRestart: one restart at the end instead of one per property
    try {
        Write-Sub "Restarting the adapter to apply everything..." DarkGray
        Restart-NetAdapter -Name $Adapter.Name -ErrorAction Stop
    } catch {
        Write-Host "   Could not restart the adapter automatically - disable/enable it or reboot." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------
# Find the active adapter (for auto mode)
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
# Profile selection
# ---------------------------------------------------------------------
function Choose-Profile {
    Write-Head "Select a preset"
    $items = @(
        @("1","Home            - plugged in: all power saving OFF, rest = Windows default"),
        @("2","Work laptop     - all power saving ON"),
        @("3","Gaming PC/laptop- lowest ping / jitter"),
        @("4","Max battery     - longest battery life (lower TX power, no wake-ups)"),
        @("5","Max speed       - highest throughput (widest channels, max buffers)")
    )
    foreach ($it in $items) {
        Write-Host ("  {0}) " -f $it[0]) -ForegroundColor White -NoNewline
        Write-Host $it[1] -ForegroundColor Gray
    }
    Write-Host "  0) " -ForegroundColor White -NoNewline
    Write-Host "Back" -ForegroundColor DarkGray
    $c = Read-Host "`nYour choice"
    if ($c -eq "0") { return $null }
    if (-not $ProfileNames.ContainsKey($c)) {
        Write-Host "Invalid choice." -ForegroundColor Red
        return Choose-Profile
    }
    return $ProfileNames[$c]
}

# ---------------------------------------------------------------------
# Manual adapter selection (list)
# ---------------------------------------------------------------------
function Select-AdapterManual {
    $all = @(Get-AllPhysicalAdapters)
    if ($all.Count -eq 0) {
        Write-Host "No adapters found." -ForegroundColor Red
        return $null
    }
    Write-Head "Available adapters"
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
    Write-Host "Back" -ForegroundColor DarkGray
    $sel = Read-Host "`nAdapter number"
    if ($sel -eq "0" -or -not $sel) { return $null }
    $idx = 0
    if (-not [int]::TryParse($sel, [ref]$idx)) { Write-Host "Invalid number." -ForegroundColor Red; return $null }
    $idx--
    if ($idx -lt 0 -or $idx -ge $all.Count) {
        Write-Host "Invalid number." -ForegroundColor Red
        return $null
    }
    return $all[$idx]
}

# =====================================================================
#  DNS: pick the fastest server (DNS Jumper style)
#  Reads the server lists from DnsJumper.ini (same folder as the script),
#  sends real DNS queries over UDP/53 to every server in parallel,
#  ranks them by response time and applies the chosen one to the adapter.
# =====================================================================
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:DnsIniPath = Join-Path $ScriptDir "DnsJumper.ini"

# Used only when DnsJumper.ini cannot be found
$script:BuiltInDns = @(
    @("IPv4","Default","US - Google Public DNS","8.8.8.8","8.8.4.4"),
    @("IPv4","Default","AU - Cloudflare","1.1.1.1","1.0.0.1"),
    @("IPv4","Default","US - Quad9 Security","9.9.9.9","149.112.112.112"),
    @("IPv4","Default","US - OpenDNS","208.67.222.222","208.67.220.220"),
    @("IPv4","Default","RU - AdGuard","94.140.14.14","94.140.15.15"),
    @("IPv6","Default","US - Google Public DNS","2001:4860:4860::8888","2001:4860:4860::8844"),
    @("IPv6","Default","AU - Cloudflare","2606:4700:4700::1111","2606:4700:4700::1001"),
    @("IPv6","Default","US - Quad9 Security","2620:fe::fe","2620:fe::9")
)

function Read-DnsJumperIni {
    param([string]$Path)
    $servers = New-Object System.Collections.ArrayList
    $cfg = @{ Domain = "www.google.com"; Timeout = 500 }
    $section = ""
    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {      # BOM-aware (the .ini is UTF-16 LE)
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith(";")) { continue }
        if ($line -match '^\[(.+)\]$') { $section = $Matches[1]; continue }

        if ($section -eq "Main") {
            if ($line -match '^ResolveDomainName\s*=\s*(.+)$')                       { $cfg.Domain  = $Matches[1].Trim() }
            elseif ($line -match '^ResolveWaitTime\s*=\s*\w+\s*,\s*(\d+)')           { $cfg.Timeout = [int]$Matches[1] }
            continue
        }
        if ($section -match '^Ipv([46])_(Default|Family|Secure)$') {
            $family = "IPv" + $Matches[1]
            $group  = $Matches[2]
        } else { continue }

        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { continue }
        $name  = $line.Substring(0, $eq).Trim()
        $parts = @($line.Substring($eq + 1).Split(",") | ForEach-Object { $_.Trim() })
        if ($parts -contains "False") { continue }                  # disabled in DNS Jumper

        $ip = $null
        $primary   = $null
        $secondary = $null
        if ($parts.Count -ge 1 -and [System.Net.IPAddress]::TryParse($parts[0], [ref]$ip)) { $primary = $parts[0] }
        if ($parts.Count -ge 2 -and [System.Net.IPAddress]::TryParse($parts[1], [ref]$ip)) { $secondary = $parts[1] }
        if (-not $primary) { continue }

        [void]$servers.Add([pscustomobject]@{
            Family = $family; Group = $group; Name = $name; Primary = $primary; Secondary = $secondary
        })
    }
    return [pscustomobject]@{ Servers = $servers; Domain = $cfg.Domain; Timeout = $cfg.Timeout }
}

function Get-DnsServerSet {
    # Returns the parsed ini (or the built-in list) - asks for another path if the ini is missing
    $path = $script:DnsIniPath
    while (-not (Test-Path -LiteralPath $path)) {
        Write-Host "  DnsJumper.ini not found at: $path" -ForegroundColor Yellow
        $in = Read-Host "  Full path to DnsJumper.ini (Enter = use the small built-in list)"
        if (-not $in) {
            $list = foreach ($e in $script:BuiltInDns) {
                [pscustomobject]@{ Family = $e[0]; Group = $e[1]; Name = $e[2]; Primary = $e[3]; Secondary = $e[4] }
            }
            return [pscustomobject]@{ Servers = @($list); Domain = "www.google.com"; Timeout = 800 }
        }
        $path = $in.Trim('"')
    }
    $script:DnsIniPath = $path
    return Read-DnsJumperIni $path
}

function Test-DnsAddresses {
    # Parallel UDP DNS probes. Returns hashtable: ip -> median RTT in ms ($null = no valid answer)
    param([string[]]$Ips, [string]$Domain, [int]$TimeoutMs, [int]$Tries = 3)

    $probe = {
        param($Ip, $Domain, $TimeoutMs, $Tries)
        $times = New-Object System.Collections.Generic.List[double]
        try {
            $addr = [System.Net.IPAddress]::Parse($Ip)
            $q = New-Object System.Collections.Generic.List[byte]
            $q.AddRange([byte[]](0x12,0x34, 0x01,0x00, 0x00,0x01, 0x00,0x00, 0x00,0x00, 0x00,0x00))   # header: RD=1, QDCOUNT=1
            foreach ($label in $Domain.Split(".")) {
                $b = [System.Text.Encoding]::ASCII.GetBytes($label)
                $q.Add([byte]$b.Length)
                $q.AddRange($b)
            }
            $q.AddRange([byte[]](0x00, 0x00,0x01, 0x00,0x01))                                          # root, QTYPE=A, QCLASS=IN
            $pkt = $q.ToArray()
            for ($i = 0; $i -lt $Tries; $i++) {
                $sock = New-Object System.Net.Sockets.Socket($addr.AddressFamily, [System.Net.Sockets.SocketType]::Dgram, [System.Net.Sockets.ProtocolType]::Udp)
                try {
                    $sock.ReceiveTimeout = $TimeoutMs
                    $sock.SendTimeout    = $TimeoutMs
                    $sock.Connect($addr, 53)
                    $pkt[0] = [byte](Get-Random -Maximum 256)
                    $pkt[1] = [byte](Get-Random -Maximum 256)
                    $buf = New-Object byte[] 4096
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    [void]$sock.Send($pkt)
                    $n = $sock.Receive($buf)
                    $sw.Stop()
                    $idOk    = ($buf[0] -eq $pkt[0]) -and ($buf[1] -eq $pkt[1])
                    $rcodeOk = (($buf[3] -band 0x0F) -eq 0)
                    $hasAns  = (($buf[6] -ne 0) -or ($buf[7] -ne 0))
                    if ($n -ge 12 -and $idOk -and $rcodeOk -and $hasAns) { $times.Add($sw.Elapsed.TotalMilliseconds) }
                } catch {} finally { $sock.Close() }
            }
        } catch {}
        $times.ToArray()
    }

    $pool = [runspacefactory]::CreateRunspacePool(1, 16)
    $pool.Open()
    $jobs = @{}
    foreach ($ip in $Ips) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($probe.ToString()).AddArgument($ip).AddArgument($Domain).AddArgument($TimeoutMs).AddArgument($Tries)
        $jobs[$ip] = @{ PS = $ps; Handle = $ps.BeginInvoke() }
    }

    $total = $jobs.Count
    do {
        $done = @($jobs.Values | Where-Object { $_.Handle.IsCompleted }).Count
        Write-Progress -Activity "Testing DNS servers ($Domain)" -Status "$done / $total" -PercentComplete ([int](100 * $done / [Math]::Max(1, $total)))
        Start-Sleep -Milliseconds 150
    } while ($done -lt $total)
    Write-Progress -Activity "Testing DNS servers" -Completed

    $result = @{}
    foreach ($ip in $jobs.Keys) {
        $vals = @()
        try { $vals = @($jobs[$ip].PS.EndInvoke($jobs[$ip].Handle) | ForEach-Object { [double]$_ }) } catch {}
        if ($vals.Count -gt 0) {
            $sorted = @($vals | Sort-Object)
            $result[$ip] = $sorted[[int][Math]::Floor(($sorted.Count - 1) / 2)]     # median
        } else {
            $result[$ip] = $null
        }
        $jobs[$ip].PS.Dispose()
    }
    $pool.Close(); $pool.Dispose()
    return $result
}

function Get-MsColor($ms) {
    if ($null -eq $ms) { return "Red" }
    if ($ms -lt 30)    { return "Green" }
    if ($ms -lt 80)    { return "Yellow" }
    return "DarkYellow"
}

function Show-DnsRanking {
    param($Rows)
    Write-Host ""
    Write-Host ("   {0,3}  {1,-40} {2,9} {3,9}   {4}" -f "#", "Server", "Primary", "Secondary", "Addresses") -ForegroundColor DarkGray
    $n = 0
    foreach ($r in $Rows) {
        $n++
        $p = if ($null -ne $r.PrimaryMs)   { "{0,6:N0} ms" -f $r.PrimaryMs }   else { "   timeout" }
        $s = if (-not $r.Secondary)        { "         -" }
                elseif ($null -ne $r.SecondaryMs) { "{0,6:N0} ms" -f $r.SecondaryMs } else { "   timeout" }
        Write-Host ("   {0,3}  " -f $n) -ForegroundColor White -NoNewline
        Write-Host ("{0,-40} " -f $r.Name) -ForegroundColor White -NoNewline
        Write-Host $p -ForegroundColor (Get-MsColor $r.PrimaryMs) -NoNewline
        Write-Host " " -NoNewline
        $sc = if ($r.Secondary) { Get-MsColor $r.SecondaryMs } else { "DarkGray" }
        Write-Host $s -ForegroundColor $sc -NoNewline
        $addr = $r.Primary; if ($r.Secondary) { $addr += ", " + $r.Secondary }
        Write-Host ("   " + $addr) -ForegroundColor DarkGray
    }
}

function Select-TargetAdapter {
    Write-Head "Adapter"
    Write-Host "  1) " -ForegroundColor White -NoNewline; Write-Host "Active adapter (auto-detect)" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline; Write-Host "Choose from the list" -ForegroundColor Gray
    Write-Host "  0) " -ForegroundColor White -NoNewline; Write-Host "Back" -ForegroundColor DarkGray
    $c = Read-Host "`nYour choice"
    switch ($c) {
        "1" {
            $a = Get-ActiveAdapter
            if (-not $a) { Write-Host "  No active adapter found." -ForegroundColor Red; return $null }
            Write-Sub ("Adapter: {0}  [{1}]" -f $a.Name, $a.InterfaceDescription) White
            return $a
        }
        "2" { return Select-AdapterManual }
        default { return $null }
    }
}

function Get-DnsProvider {
    # "US - Google Public DNS" -> "google", "AU - Cloudflare Malware Blocking" -> "cloudflare"
    param([string]$Name)
    $n = $Name
    $i = $n.IndexOf(" - ")
    if ($i -ge 0) { $n = $n.Substring($i + 3) }
    return ($n.Trim().Split(" ")[0]).ToLower()
}

function Resolve-DnsPick {
    # token = list number OR part of a server name (fastest answering match wins)
    param([string]$Token, $Rows)
    $i = 0
    if ([int]::TryParse($Token, [ref]$i)) {
        if ($i -ge 1 -and $i -le $Rows.Count) { return $Rows[$i - 1] }
        return $null
    }
    $m = @($Rows | Where-Object { $_.Name.IndexOf($Token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if ($m.Count -eq 0) { return $null }
    $a = @($m | Where-Object { $null -ne $_.PrimaryMs })
    if ($a.Count -gt 0) { return $a[0] }
    return $m[0]
}

function Invoke-DnsBenchmark {
    param($Adapter)

    Write-Head "What to test"
    Write-Host "  IP version:  1) IPv4   2) IPv6   0) Back" -ForegroundColor Gray
    $v = Read-Host "`nYour choice"
    if ($v -eq "1") { $family = "IPv4" } elseif ($v -eq "2") { $family = "IPv6" } else { return }

    Write-Host "  Group:  1) Default   2) Family (filtered)   3) Secure (malware blocking)   4) All" -ForegroundColor Gray
    $g = Read-Host "`nYour choice"
    $groups = switch ($g) { "1" { @("Default") } "2" { @("Family") } "3" { @("Secure") } "4" { @("Default","Family","Secure") } default { return } }

    $set = Get-DnsServerSet
    $list = @($set.Servers | Where-Object { $_.Family -eq $family -and $groups -contains $_.Group })
    if ($list.Count -eq 0) { Write-Host "  No servers in this selection." -ForegroundColor Red; return }

    # same Name+Primary can appear in several groups (e.g. Comodo Secure) - test once
    $list = @($list | Group-Object Name, Primary | ForEach-Object { $_.Group[0] })

    $ips = @($list | ForEach-Object { $_.Primary; if ($_.Secondary) { $_.Secondary } } | Select-Object -Unique)
    Write-Head ("Testing {0} {1} servers ({2} addresses) via {3}" -f $list.Count, $family, $ips.Count, $set.Domain)
    Write-Sub ("3 queries per address, timeout {0} ms, median is used" -f $set.Timeout) DarkGray
    $res = Test-DnsAddresses -Ips $ips -Domain $set.Domain -TimeoutMs $set.Timeout -Tries 3

    $rows = foreach ($s in $list) {
        $pm = $res[$s.Primary]
        $sm = if ($s.Secondary) { $res[$s.Secondary] } else { $null }
        # Rank by the PRIMARY address (it is the one that is queried first and the one used in mixed pairs);
        # the secondary only breaks ties. A dead primary goes behind every healthy server.
        if ($null -ne $pm) {
            $score = $pm
            if ($s.Secondary) { if ($null -ne $sm) { $score += $sm / 1000 } else { $score += 0.5 } }
        } elseif ($null -ne $sm) { $score = 100000 + $sm }
        else { $score = [double]::MaxValue }
        [pscustomobject]@{
            Name = $s.Name; Primary = $s.Primary; Secondary = $s.Secondary
            PrimaryMs = $pm; SecondaryMs = $sm; Score = $score
        }
    }
    $rows = @($rows | Sort-Object Score)
    Show-DnsRanking $rows

    $alive = @($rows | Where-Object { $null -ne $_.PrimaryMs })
    if ($alive.Count -eq 0) {
        Write-Host "`n  No server answered." -ForegroundColor Red
        if ($family -eq "IPv6") { Write-Host "  (this network probably has no working IPv6)" -ForegroundColor DarkGray }
        return
    }

    Write-Host ""
    Write-Host ("  What to apply to '{0}':" -f $Adapter.Name) -ForegroundColor White
    Write-Host "    Enter   auto-mix: fastest server = PRIMARY, fastest server of ANOTHER provider = SECONDARY" -ForegroundColor Gray
    Write-Host "    s       auto-single: fastest server with its own secondary address" -ForegroundColor Gray
    Write-Host "    N       server N with its own secondary address" -ForegroundColor Gray
    Write-Host "    N,M     PRIMARY from server N + SECONDARY from server M   (e.g. 3,7  or  cloudflare,nextdns)" -ForegroundColor Gray
    Write-Host "    0       change nothing" -ForegroundColor DarkGray
    $pick = ([string](Read-Host "`nYour choice")).Trim()
    if ($pick -eq "0") { return }

    $addrs = $null
    $label = $null
    $chosen = @()

    if (-not $pick) {
        # ---- auto-mix: two best DIFFERENT providers
        $p1 = $alive[0]
        $prov1 = Get-DnsProvider $p1.Name
        $p2 = @($alive | Where-Object { (Get-DnsProvider $_.Name) -ne $prov1 })[0]
        if ($p2) {
            $addrs = @($p1.Primary, $p2.Primary)
            $label = "{0}  +  {1}" -f $p1.Name, $p2.Name
            $chosen = @($p1, $p2)
        } else {
            Write-Host "  Only one provider answered - using its own primary + secondary." -ForegroundColor Yellow
            $addrs = @($p1.Primary); if ($p1.Secondary) { $addrs += $p1.Secondary }
            $label = $p1.Name
            $chosen = @($p1)
        }
    }
    elseif ($pick -eq "s" -or $pick -eq "S") {
        $p1 = $alive[0]
        $addrs = @($p1.Primary); if ($p1.Secondary) { $addrs += $p1.Secondary }
        $label = $p1.Name
        $chosen = @($p1)
    }
    else {
        $tokens = @($pick -split '\s*[,+;]\s*' | Where-Object { $_ })
        if ($tokens.Count -lt 1 -or $tokens.Count -gt 2) { Write-Host "  Invalid input." -ForegroundColor Red; return }
        $r1 = Resolve-DnsPick $tokens[0] $rows
        if (-not $r1) { Write-Host ("  '{0}' not found in the list." -f $tokens[0]) -ForegroundColor Red; return }
        if ($tokens.Count -eq 2) {
            $r2 = Resolve-DnsPick $tokens[1] $rows
            if (-not $r2) { Write-Host ("  '{0}' not found in the list." -f $tokens[1]) -ForegroundColor Red; return }
            if ($r1.Primary -eq $r2.Primary) { Write-Host "  Primary and secondary are the same server." -ForegroundColor Red; return }
            $addrs = @($r1.Primary, $r2.Primary)
            $label = "{0}  +  {1}" -f $r1.Name, $r2.Name
            $chosen = @($r1, $r2)
        } else {
            $addrs = @($r1.Primary); if ($r1.Secondary) { $addrs += $r1.Secondary }
            $label = $r1.Name
            $chosen = @($r1)
        }
    }

    if (@($chosen | Where-Object { $null -eq $_.PrimaryMs }).Count -gt 0) {
        $yn = Read-Host "  A chosen server did not answer the test. Apply anyway? (y/N)"
        if ($yn -notmatch '^[yY]') { return }
    }

    # preview + optional swap (Windows asks the primary first)
    while ($true) {
        Write-Host ""
        Write-Host "  Primary  : " -ForegroundColor Gray -NoNewline; Write-Host $addrs[0] -ForegroundColor White
        if ($addrs.Count -gt 1) { Write-Host "  Secondary: " -ForegroundColor Gray -NoNewline; Write-Host $addrs[1] -ForegroundColor White }
        if ($addrs.Count -lt 2) { break }
        $ok = ([string](Read-Host "  Enter = apply,  w = swap primary/secondary,  0 = cancel")).Trim()
        if ($ok -eq "0") { return }
        if ($ok -eq "w" -or $ok -eq "W") { $addrs = @($addrs[1], $addrs[0]); continue }
        break
    }
    try {
        Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $addrs -ErrorAction Stop
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Status "OK  " "Green" ("DNS on '{0}' -> {1}" -f $Adapter.Name, $label)
        Write-Sub "DNS cache flushed." DarkGray
    } catch {
        Write-Status "FAIL" "Red" $_.Exception.Message
    }
}

function Invoke-DnsMenu {
    $adapter = Select-TargetAdapter
    if (-not $adapter) { return }

    while ($true) {
        Write-Head ("DNS - {0}" -f $adapter.Name)
        $cur = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        foreach ($c in @($cur)) {
            $txt = if ($c.ServerAddresses.Count -gt 0) { $c.ServerAddresses -join ", " } else { "(automatic / none)" }
            Write-Sub ("Current {0}: {1}" -f $(if ($c.AddressFamily -eq 2) { "IPv4" } else { "IPv6" }), $txt) DarkGray
        }
        Write-Host "  1) " -ForegroundColor White -NoNewline; Write-Host "Benchmark servers and apply the fastest / chosen one" -ForegroundColor Gray
        Write-Host "  2) " -ForegroundColor White -NoNewline; Write-Host "Reset DNS to automatic (DHCP)" -ForegroundColor Gray
        Write-Host "  0) " -ForegroundColor White -NoNewline; Write-Host "Back" -ForegroundColor DarkGray
        $c = Read-Host "`nYour choice"
        switch ($c) {
            "1" { Invoke-DnsBenchmark $adapter }
            "2" {
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    Write-Status "OK  " "Green" "DNS reset to automatic"
                } catch { Write-Status "FAIL" "Red" $_.Exception.Message }
            }
            "0" { return }
            default { Write-Host "Invalid choice." -ForegroundColor Red }
        }
    }
}

# ---------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------
Write-Banner

:main while ($true) {
    Write-Head "Main menu"
    Write-Host "  1) " -ForegroundColor White -NoNewline
    Write-Host "Auto-detect the active adapter" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline
    Write-Host "Select an adapter manually" -ForegroundColor Gray
    Write-Host "  3) " -ForegroundColor White -NoNewline
    Write-Host "Apply to both Ethernet and Wi-Fi at once" -ForegroundColor Gray
    Write-Host "  4) " -ForegroundColor White -NoNewline
    Write-Host "DNS: find the fastest server (DnsJumper.ini) and apply it" -ForegroundColor Gray
    Write-Host "  0) " -ForegroundColor White -NoNewline
    Write-Host "Exit" -ForegroundColor DarkGray
    $mode = Read-Host "`nYour choice"

    if ($mode -eq "0") { exit }

    $applied    = $false
    $profileKey = $null

    switch ($mode) {

        "1" {
            Write-Head "Searching for the active adapter"
            $adapter = Get-ActiveAdapter
            if (-not $adapter) {
                Write-Host "  No active adapter found." -ForegroundColor Red
                continue main
            }
            Show-AdapterCard $adapter

            $profileKey = Choose-Profile
            if (-not $profileKey) { continue main }
            Apply-Preset $adapter $profileKey
            $applied = $true
        }

        "2" {
            $adapter = Select-AdapterManual
            if (-not $adapter) { continue main }
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
                Write-Host "Neither Ethernet nor Wi-Fi adapters were found." -ForegroundColor Red
                continue main
            }

            Write-Head "Adapters found for simultaneous configuration"
            foreach ($a in $ethAdapters)  { Show-AdapterCard $a }
            foreach ($a in $wifiAdapters) { Show-AdapterCard $a }

            $profileKey = Choose-Profile
            if (-not $profileKey) { continue main }

            foreach ($a in $ethAdapters)  { Apply-Preset $a $profileKey }
            foreach ($a in $wifiAdapters) { Apply-Preset $a $profileKey }
            $applied = $true
        }

        "4" {
            Invoke-DnsMenu
            continue main
        }

        default {
            Write-Host "Invalid choice." -ForegroundColor Red
            continue main
        }
    }

    if ($applied) {
        # global (non per-adapter) tweaks: once per run
        Apply-GlobalNetTweaks $profileKey

        Write-Head "Done"
        Write-Host "  You can verify the applied values with this command:" -ForegroundColor Gray
        Write-Host '  Get-NetAdapterAdvancedProperty -Name "<Adapter name>" | Format-Table DisplayName,RegistryKeyword,RegistryValue -AutoSize' -ForegroundColor DarkYellow
        if ($profileKey -eq "GamePC") {
            Write-Host ""
            Write-Host "  Gaming PC: reboot once so the NDIS parameters take effect." -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "  Press any key to return to the menu..." -ForegroundColor Cyan
        $null = [System.Console]::ReadKey($true)
    }
}
