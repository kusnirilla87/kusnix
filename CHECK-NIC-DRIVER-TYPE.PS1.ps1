Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

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

    if ($p -match '(".*?\.sys")') {
        $candidate = $Matches[1].Trim('"')
    } elseif ($p -match '([A-Za-z]:\\.*?\.sys)') {
        $candidate = $Matches[1]
    } elseif ($p -match '(\\.*?\.sys)') {
        $candidate = $Matches[1]
    } else {
        $candidate = $p.Trim('"')
    }

    if (Test-Path $candidate) { return $candidate }

    try {
        $alt = Join-Path $env:SystemRoot ($candidate.TrimStart('\'))
        if (Test-Path $alt) { return $alt }
    } catch {}

    return $null
}

function Get-DriverTypeFromBinary {
    param([string]$SysPath)

    if (-not $SysPath -or -not (Test-Path $SysPath)) { return "NDIS" }  

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

$results = @()

# Отримуємо фізичні та реальні мережеві адаптери, відсікаючи WAN Miniport та програмні заглушки
Get-CimInstance -ClassName Win32_NetworkAdapter |
    Where-Object { 
        $_.PNPDeviceID -and 
        $_.PhysicalAdapter -eq $true -and 
        $_.Name -notmatch 'WAN Miniport|Kernel|Loopback|Microsoft Wi-Fi Direct Virtual'
    } |
    ForEach-Object {
        $name = $_.Name
        $pnp  = $_.PNPDeviceID

        $enumKey   = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnp"
        $driverKey = (Get-ItemProperty -Path $enumKey -Name "Driver").Driver
        if (-not $driverKey) { return }

        $ndiKey     = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driverKey\Ndi"
        $service    = (Get-ItemProperty -Path $ndiKey -Name "Service").Service
        if (-not $service) { return }
        $service    = $service.TrimEnd('.')

        $svcKey     = "HKLM:\SYSTEM\CurrentControlSet\Services\$service"
        $imagePath  = (Get-ItemProperty -Path $svcKey -Name "ImagePath").ImagePath
        $resolved   = Resolve-DriverImagePath $imagePath
        $type       = Get-DriverTypeFromBinary $resolved

        $results += [pscustomobject]@{
            AdapterName   = $name
            PNPDeviceID   = $pnp
            Service       = $service
            ImagePath     = $imagePath
            ResolvedSys   = $resolved
            DriverType    = $type
        }
    }

Write-Host ""
if (-not $results -or $results.Count -eq 0) {
    Write-Host "Мережевих адаптерів не знайдено." -ForegroundColor Yellow
} else {
    # Форматований вивід із колірним підсвічуванням
    $results | Sort-Object AdapterName | ForEach-Object {
        Write-Host "Адаптер: " -NoNewline
        Write-Host $_.AdapterName -ForegroundColor Green
        
        Write-Host "Тип драйвера: " -NoNewline
        Write-Host $_.DriverType -ForegroundColor Yellow
        
        Write-Host "Служба: " -NoNewline
        Write-Host $_.Service -ForegroundColor Gray
        
        Write-Host "Файл .sys: " -NoNewline
        Write-Host $_.ResolvedSys -ForegroundColor Gray
        
        Write-Host ("-" * 60) -ForegroundColor DarkGray
    }
}

Write-Host ""
Read-Host "Натисніть Enter для виходу"