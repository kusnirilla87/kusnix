#requires -RunAsAdministrator
# =====================================================================
#  NetAdapterPreset.ps1
#  Auto-detection of Wired/Wi-Fi + Intel/Realtek, applies presets
#  for Advanced Properties.
#
#  Profiles:  1) Home laptop   2) Work laptop
#             3) Home PC       4) Gaming PC/laptop
#
#  Operating modes:
#    A) Auto   - detects the active adapter and its type automatically
#    B) Manual - shows a list of all adapters, you pick the one you need
#    C) Both   - applies the preset to both Ethernet and Wi-Fi at once
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
# Helper function to apply a property
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
        Write-Host ("] {0,-28} (property not present on this adapter)" -f $Keyword) -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------
# Determine the type (Ethernet/Wi-Fi) and vendor (Intel/Realtek)
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
# Determine the driver type: NDIS (legacy) or NetAdapterCx (modern)
# Logic taken from CHECK-NIC-DRIVER-TYPE.ps1
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
    Write-Host "Connection type: " -ForegroundColor Gray -NoNewline
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
# Profiles: HomeLaptop, WorkLaptop, HomePC, GamePC
# Comments correspond to the collected tables (intel/realtek eth/wifi).
# ---------------------------------------------------------------------

$Presets = @{}

# ===================== INTEL ETHERNET =====================
# Keys and values verified against a real registry dump (Ndi\Params) of the
# user's Intel(R) Ethernet Connection (6) I219-LM card - 100% match.
$Presets.Intel = @{}
$Presets.Intel.Ethernet = @{
    HomeLaptop = @{
        "WaitAutoNegComplete"    = @("2","Wait for Link: Auto Detect")
        "WakeOnLink"             = @("0","Wake on Link Settings: Disabled")
        "ReduceSpeedOnPowerDown" = @("1","Enabled")
        "SipsEnabled"            = @("1","System Idle Power Saver: Enabled")
        "MasterSlave"            = @("0","Gigabit Master Slave Mode: Auto Detect")
        "LinkNegotiationProcess" = @("1","Legacy Switch Compatibility Mode: Auto")
        "LogLinkStateEvent"      = @("16","Log Link State Event: Disabled")
        "ITR"                    = @("65535","Interrupt Moderation Rate: Adaptive")
        "EEELinkAdvertisement"   = @("1","EEE: On")
        "EnablePME"              = @("0","Enable PME: Disabled")
        "AdaptiveIFS"            = @("0","Adaptive Inter-Frame Spacing: Disabled")
        "AutoPowerSaveModeEnabled"=@("1","Link Speed Battery Saver: Enabled")
        "*WakeOnMagicPacket"     = @("0","Disabled")
        "*WakeOnPattern"         = @("0","Disabled")
        "*UDPChecksumOffloadIPv4"= @("3","Rx & Tx Enabled")
        "*TCPChecksumOffloadIPv6"= @("3","Rx & Tx Enabled")
        "*SpeedDuplex"           = @("0","Auto Negotiation")
        "*RSS"                   = @("1","Enabled")
        "*PriorityVLANTag"       = @("3","Packet Priority & VLAN Enabled")
        "*PtpHardwareTimestamp"  = @("0","Disabled")
        "*PMARPOffload"          = @("1","Enabled")
        "*NumRssQueues"          = @("1","1 Queue")
        "*LsoV2IPv4"             = @("1","Enabled")
        "*IPChecksumOffloadIPv4" = @("3","Rx & Tx Enabled")
        "*JumboPacket"           = @("1514","Disabled (no jumbo frames)")
        "*FlowControl"           = @("3","Rx & Tx Enabled")
        "*InterruptModeration"  = @("1","Enabled")
    }
    WorkLaptop = @{
        "WaitAutoNegComplete"    = @("2","Wait for Link: Auto Detect")
        "WakeOnLink"             = @("0","Wake on Link Settings: Disabled")
        "ReduceSpeedOnPowerDown" = @("1","Enabled")
        "SipsEnabled"            = @("1","System Idle Power Saver: Enabled")
        "MasterSlave"            = @("0","Gigabit Master Slave Mode: Auto Detect")
        "LinkNegotiationProcess" = @("1","Legacy Switch Compatibility Mode: Auto")
        "LogLinkStateEvent"      = @("16","Log Link State Event: Disabled")
        "ITR"                    = @("65535","Interrupt Moderation Rate: Adaptive")
        "EEELinkAdvertisement"   = @("1","EEE: On")
        "EnablePME"              = @("1","Enable PME: Enabled")
        "AdaptiveIFS"            = @("0","Adaptive Inter-Frame Spacing: Disabled")
        "AutoPowerSaveModeEnabled"=@("1","Link Speed Battery Saver: Enabled")
        "*WakeOnMagicPacket"     = @("0","Disabled")
        "*WakeOnPattern"         = @("0","Disabled")
        "*UDPChecksumOffloadIPv4"= @("3","Rx & Tx Enabled")
        "*TCPChecksumOffloadIPv6"= @("3","Rx & Tx Enabled")
        "*SpeedDuplex"           = @("0","Auto Negotiation")
        "*RSS"                   = @("1","Enabled")
        "*PriorityVLANTag"       = @("3","Packet Priority & VLAN Enabled")
        "*PtpHardwareTimestamp"  = @("0","Disabled")
        "*PMARPOffload"          = @("1","Enabled")
        "*NumRssQueues"          = @("1","1 Queue")
        "*LsoV2IPv4"             = @("1","Enabled")
        "*IPChecksumOffloadIPv4" = @("3","Rx & Tx Enabled")
        "*JumboPacket"           = @("1514","Disabled (no jumbo frames)")
        "*FlowControl"           = @("3","Rx & Tx Enabled")
        "*InterruptModeration"  = @("1","Enabled")
    }
    HomePC = @{
        "WaitAutoNegComplete"    = @("2","Wait for Link: Auto Detect")
        "WakeOnLink"             = @("0","Wake on Link Settings: Disabled")
        "ReduceSpeedOnPowerDown" = @("0","Disabled (desktop PC)")
        "SipsEnabled"            = @("0","System Idle Power Saver: Disabled")
        "MasterSlave"            = @("0","Gigabit Master Slave Mode: Auto Detect")
        "LinkNegotiationProcess" = @("1","Legacy Switch Compatibility Mode: Auto")
        "LogLinkStateEvent"      = @("16","Log Link State Event: Disabled")
        "ITR"                    = @("65535","Interrupt Moderation Rate: Adaptive")
        "EEELinkAdvertisement"   = @("0","EEE: Off")
        "EnablePME"              = @("0","Enable PME: Disabled")
        "AdaptiveIFS"            = @("0","Adaptive Inter-Frame Spacing: Disabled")
        "AutoPowerSaveModeEnabled"=@("0","Link Speed Battery Saver: Disabled")
        "*WakeOnMagicPacket"     = @("0","Disabled")
        "*WakeOnPattern"         = @("0","Disabled")
        "*UDPChecksumOffloadIPv4"= @("3","Rx & Tx Enabled")
        "*TCPChecksumOffloadIPv6"= @("3","Rx & Tx Enabled")
        "*SpeedDuplex"           = @("0","Auto Negotiation")
        "*RSS"                   = @("1","Enabled")
        "*PriorityVLANTag"       = @("3","Packet Priority & VLAN Enabled")
        "*PtpHardwareTimestamp"  = @("0","Disabled")
        "*PMARPOffload"          = @("1","Enabled")
        "*NumRssQueues"          = @("2","2 Queues")
        "*LsoV2IPv4"             = @("1","Enabled")
        "*IPChecksumOffloadIPv4" = @("3","Rx & Tx Enabled")
        "*JumboPacket"           = @("1514","Disabled (no jumbo frames)")
        "*FlowControl"           = @("3","Rx & Tx Enabled")
        "*InterruptModeration"  = @("1","Enabled")
    }
    GamePC = @{
        "WaitAutoNegComplete"    = @("2","Wait for Link: Auto Detect")
        "WakeOnLink"             = @("0","Wake on Link Settings: Disabled")
        "ReduceSpeedOnPowerDown" = @("0","Disabled")
        "SipsEnabled"            = @("0","System Idle Power Saver: Disabled")
        "MasterSlave"            = @("0","Gigabit Master Slave Mode: Auto Detect")
        "LinkNegotiationProcess" = @("2","Legacy Switch Compatibility Mode: Force")
        "EEELinkAdvertisement"   = @("0","EEE: Off")
        "EnablePME"              = @("0","Enable PME: Disabled")
        "AdaptiveIFS"            = @("0","Adaptive Inter-Frame Spacing: Disabled")
        "AutoPowerSaveModeEnabled"=@("0","Link Speed Battery Saver: Disabled")
        "*WakeOnMagicPacket"     = @("0","Disabled")
        "*WakeOnPattern"         = @("0","Disabled")
        "*UDPChecksumOffloadIPv4"= @("3","Rx & Tx Enabled")
        "*TCPChecksumOffloadIPv6"= @("3","Rx & Tx Enabled")
        "*SpeedDuplex"           = @("0","Auto Negotiation")
        "*RSS"                   = @("1","Enabled")
        "*PriorityVLANTag"       = @("3","Packet Priority & VLAN Enabled")
        "*PtpHardwareTimestamp"  = @("0","Disabled")
        "*PMARPOffload"          = @("1","Enabled")
        "*NumRssQueues"          = @("4","4 Queues")
        "*LsoV2IPv4"             = @("1","Enabled")
        "*IPChecksumOffloadIPv4" = @("3","Rx & Tx Enabled")
        "*JumboPacket"           = @("1514","Disabled (no jumbo frames)")
        "*FlowControl"           = @("0","Disabled (min. jitter)")
        "*InterruptModeration"  = @("0","Disabled (min. latency)")
    }
}
# Common Intel Ethernet values, identical across all 4 profiles
# (taken 1:1 from intelethernet.txt - lines that weren't split by column):
foreach ($p in @("HomeLaptop","WorkLaptop","HomePC","GamePC")) {
    $Presets.Intel.Ethernet[$p]["*PMNSOffload"]           = @("1","Enabled")
    $Presets.Intel.Ethernet[$p]["*LsoV2IPv6"]              = @("1","Enabled")
    $Presets.Intel.Ethernet[$p]["*TCPChecksumOffloadIPv4"] = @("3","Rx & Tx Enabled")
    $Presets.Intel.Ethernet[$p]["*UDPChecksumOffloadIPv6"] = @("3","Rx & Tx Enabled")
}

# ===================== INTEL WI-FI =====================
# Keys and values verified against a real registry dump (Ndi\Params) of
# the user's Intel Wi-Fi card - 100% match (enum values are real codes).
$Presets.Intel.WiFi = @{
    HomeLaptop = @{
        "uAPSDSupport"              = @("1","U-APSD: Enabled")
        "ThroughputBoosterEnabled"  = @("1","Throughput Booster: Enabled")
        "RoamingPreferredBandType"  = @("0","Preferred Band: No Preference")
        "RoamAggressiveness"        = @("2","Roaming Aggressiveness: Medium")
        "MIMOPowerSaveMode"         = @("3","MIMO Power Save: No SMPS")
        "IbssTxPower"               = @("50","Transmit Power: Medium")
        "FatChannelIntolerant"      = @("0","Fat Channel Intolerant: Disabled")
        "ChannelWidth24"            = @("1","2.4GHz Channel Width: Auto (40MHz)")
        "ChannelWidth52"            = @("1","5GHz Channel Width: Auto (80MHz)")
        "CtsToItself"               = @("1","CTS-to-self Enabled")
        "*PacketCoalescing"         = @("1","Packet Coalescing: Enabled")
        "*DeviceSleepOnDisconnect"  = @("1","Sleep on WoWLAN Disconnect: Enabled")
    }
    WorkLaptop = @{
        "uAPSDSupport"              = @("1","U-APSD: Enabled")
        "ThroughputBoosterEnabled"  = @("0","Throughput Booster: Disabled")
        "RoamingPreferredBandType"  = @("0","Preferred Band: No Preference")
        "RoamAggressiveness"        = @("4","Roaming Aggressiveness: Highest")
        "MIMOPowerSaveMode"         = @("0","MIMO Power Save: Automatic SMPS")
        "IbssTxPower"               = @("50","Transmit Power: Medium")
        "FatChannelIntolerant"      = @("1","Fat Channel Intolerant: Enabled")
        "ChannelWidth24"            = @("0","2.4GHz Channel Width: 20MHz Only")
        "ChannelWidth52"            = @("1","5GHz Channel Width: Auto (80MHz)")
        "CtsToItself"               = @("0","RTS/CTS Enabled")
        "*PacketCoalescing"         = @("1","Packet Coalescing: Enabled")
        "*DeviceSleepOnDisconnect"  = @("1","Sleep on WoWLAN Disconnect: Enabled")
    }
    HomePC = @{
        "uAPSDSupport"              = @("0","U-APSD: Disabled")
        "ThroughputBoosterEnabled"  = @("1","Throughput Booster: Enabled")
        "RoamingPreferredBandType"  = @("2","Preferred Band: 5 GHz")
        "RoamAggressiveness"        = @("2","Roaming Aggressiveness: Medium")
        "MIMOPowerSaveMode"         = @("3","MIMO Power Save: No SMPS")
        "IbssTxPower"               = @("100","Transmit Power: Highest")
        "FatChannelIntolerant"      = @("0","Fat Channel Intolerant: Disabled")
        "ChannelWidth24"            = @("1","2.4GHz Channel Width: Auto (40MHz)")
        "ChannelWidth52"            = @("1","5GHz Channel Width: Auto (80MHz)")
        "CtsToItself"               = @("1","CTS-to-self Enabled")
        "*PacketCoalescing"         = @("0","Packet Coalescing: Disabled")
        "*DeviceSleepOnDisconnect"  = @("0","Sleep on WoWLAN Disconnect: Disabled")
    }
    GamePC = @{
        "uAPSDSupport"              = @("0","U-APSD: Disabled")
        "ThroughputBoosterEnabled"  = @("1","Throughput Booster: Enabled")
        "RoamingPreferredBandType"  = @("2","Preferred Band: 5 GHz")
        "RoamAggressiveness"        = @("0","Roaming Aggressiveness: Lowest")
        "MIMOPowerSaveMode"         = @("3","MIMO Power Save: No SMPS")
        "IbssTxPower"               = @("100","Transmit Power: Highest")
        "FatChannelIntolerant"      = @("0","Fat Channel Intolerant: Disabled")
        "ChannelWidth24"            = @("1","2.4GHz Channel Width: Auto (40MHz)")
        "ChannelWidth52"            = @("1","5GHz Channel Width: Auto (80MHz)")
        "CtsToItself"               = @("1","CTS-to-self Enabled")
        "*PacketCoalescing"         = @("0","Packet Coalescing: Disabled")
        "*DeviceSleepOnDisconnect"  = @("0","Sleep on WoWLAN Disconnect: Disabled")
    }
}
# Common Intel Wi-Fi values, identical across all 4 profiles
# (taken 1:1 from intelwifi.txt - lines that weren't split by column):
foreach ($p in @("HomeLaptop","WorkLaptop","HomePC","GamePC")) {
    $Presets.Intel.WiFi[$p]["*WakeOnMagicPacket"] = @("0","Disabled")
    $Presets.Intel.WiFi[$p]["*WakeOnPattern"]     = @("0","Disabled")
    $Presets.Intel.WiFi[$p]["*PMWiFiRekeyOffload"]= @("1","Enabled")
    $Presets.Intel.WiFi[$p]["*PMARPOffload"]      = @("1","Enabled")
    $Presets.Intel.WiFi[$p]["IEEE11nMode"]        = @("2","802.11ac: Enabled")
}

# ===================== REALTEK ETHERNET =====================
# Keys and values verified against a real registry dump (Ndi\Params) of the
# user's Realtek PCIe GbE Family Controller card - 100% match.
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
        "*FlowControl"              = @("0","Disabled (min. jitter)")
        "*InterruptModeration"      = @("0","Disabled (min. latency)")
        "*NumRssQueues"             = @("4","4 Queues")
    }
}
# Common Realtek Ethernet values, identical across all 4 profiles
# (taken 1:1 from realtekETHERNEt.txt - lines that weren't split by column):
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
    $Presets.Realtek.Ethernet[$p]["*JumboPacket"]            = @("1514","Disabled (no jumbo frames)")
    $Presets.Realtek.Ethernet[$p]["*IPChecksumOffloadIPv4"]  = @("3","Rx & Tx Enabled")
}

# ===================== REALTEK WI-FI =====================
# Keys and values verified against a real registry dump (Ndi\Params) of the
# user's Realtek RTL8822CE 802.11ac PCIe Adapter card - 100% match.
# Important: WakeOnDisconnect has an INVERTED enum (0=Enabled, 1=Disabled)!
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
# Common Realtek Wi-Fi values, identical across all 4 profiles
# (taken 1:1 from realtekWIFI.txt - lines that weren't split by column):
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
    "HomeLaptop" = "Home laptop"
    "WorkLaptop" = "Work laptop"
    "HomePC"     = "Home PC"
    "GamePC"     = "Gaming PC/laptop"
}

# ---------------------------------------------------------------------
# Apply the preset to a specific adapter
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
        Write-Host "  No preset for $vendor $kind." -ForegroundColor Red
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
    Write-Head "Choose a preset"
    Write-Host "  1) " -ForegroundColor White -NoNewline
    Write-Host "Home laptop" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline
    Write-Host "Work laptop" -ForegroundColor Gray
    Write-Host "  3) " -ForegroundColor White -NoNewline
    Write-Host "Home PC" -ForegroundColor Gray
    Write-Host "  4) " -ForegroundColor White -NoNewline
    Write-Host "Gaming PC/laptop" -ForegroundColor Gray
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
# Main menu
# ---------------------------------------------------------------------
Write-Banner

:main while ($true) {
    Write-Head "Main menu"
    Write-Host "  1) " -ForegroundColor White -NoNewline
    Write-Host "Auto-detect the active adapter" -ForegroundColor Gray
    Write-Host "  2) " -ForegroundColor White -NoNewline
    Write-Host "Manually select an adapter" -ForegroundColor Gray
    Write-Host "  3) " -ForegroundColor White -NoNewline
    Write-Host "Apply to both Ethernet and Wi-Fi at once" -ForegroundColor Gray
    Write-Host "  0) " -ForegroundColor White -NoNewline
    Write-Host "Exit" -ForegroundColor DarkGray
    $mode = Read-Host "`nYour choice"

    if ($mode -eq "0") { exit }

    $applied = $false

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
            $all = @(Get-AllPhysicalAdapters)
            if ($all.Count -eq 0) {
                Write-Host "No adapters found." -ForegroundColor Red
                continue main
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
            if ($sel -eq "0" -or -not $sel) { continue main }
            $idx = [int]$sel - 1
            if ($idx -lt 0 -or $idx -ge $all.Count) {
                Write-Host "Invalid number." -ForegroundColor Red
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
                Write-Host "No Ethernet or Wi-Fi adapters found." -ForegroundColor Red
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

        default {
            Write-Host "Invalid choice." -ForegroundColor Red
            continue main
        }
    }

    if ($applied) {
        Write-Head "Done"
        Write-Host "  You can check the applied values with the command:" -ForegroundColor Gray
        Write-Host '  Get-NetAdapterAdvancedProperty -Name "<Adapter name>" | Format-Table DisplayName,RegistryKeyword,RegistryValue -AutoSize' -ForegroundColor DarkYellow
        Write-Host ""
        Write-Host "  Press any key to return to the menu..." -ForegroundColor Cyan
        $null = [System.Console]::ReadKey($true)
    }
}
