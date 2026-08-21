# KusniX

**KusniX** is a set of batch/PowerShell utilities for fine-tuning network adapters, interrupts (IRQ), CPU, and Windows system services. It's built as a console menu (`KusniX.bat`) that launches individual module scripts.

> ⚠️ **These scripts modify the Windows registry, services, and network adapter properties.**
> It's recommended to create a system restore point before use. The author(s) are not responsible for any consequences of using these scripts.

## What's included

| File | Purpose |
|---|---|
| `KusniX.bat` | Main menu. Launches with administrator rights and provides access to all modules: Windows tasks, MMCSS tweaks, disk cleanup, network adapter settings, interrupt settings, and the revert page. |
| `NetAdapterPreset.ps1` | Detects the active network adapter(s) (Ethernet/Wi-Fi, Intel/Realtek) and applies one of 4 advanced-property presets: *Home Laptop*, *Work Laptop*, *Home PC*, *Gaming PC/Laptop*. Supports auto, manual, and combined adapter-selection modes. |
| `CHECK-NIC-DRIVER-TYPE_PS1.ps1` (run via `checknic.bat`) | Detects the driver type of each physical network adapter — legacy **NDIS** or modern **NetAdapterCx**. |
| `devicetweakerllg.ps1` (run via `devicetweaker.bat`) | The main "heavy" script: CPU tuning (core parking, CPPC ratings, simulating core/thread counts for testing), forcing the NIC driver NDIS ⇄ NetAdapterCx, RSS/IRQ configuration, and backing up current values before making changes. Supports launch arguments (`-verbose`, `-AutoOptimize`, `-Backup yes/no`, `-NicMsi`, `-forceNDIS`, `-forceNetAdapterCx`, `-rss`, `-irq`, `-both`, etc.). |
| `msync.bat` / `msyncc.bat` | Disables / enables the scheduled task `SettingSync\BackgroundUploadTask` (Windows settings sync). |
| `pci.ids` | PCI device ID database ([pci-ids.ucw.cz](https://pci-ids.ucw.cz/)), used by `devicetweakerllg.ps1` to display readable hardware names. |
| `pw.exe` | [PowerRun](https://www.sordum.org/9333/powerrun-v1-6/) by sordum.org — a third-party tool for running commands with SYSTEM/TrustedInstaller privileges. Used to enable/disable settings sync. |

## Requirements

- Windows 10/11
- Administrator rights (scripts elevate themselves via UAC)
- PowerShell (Windows PowerShell 5.1, `powershell.exe`)
- The `Bypass` execution policy is set automatically by the `.bat` launchers (`-ExecutionPolicy Bypass`); nothing needs to be changed manually

## Installation

1. Clone the repository or download the archive:
   ```bash
   git clone https://github.com/<your-username>/KusniX.git
   ```
2. Place all files in a single folder, preferably `C:\kusnix\` (some `.bat` files reference this path directly).
3. Make sure `pci.ids` is located next to the scripts (for readable PCI device names). An up-to-date version can be downloaded from [pci-ids.ucw.cz](https://pci-ids.ucw.cz/v2.2/pci.ids).

## Usage

Run `KusniX.bat` — the main menu will open:

```
[1] Windows Task Settings
[2] MMCSS Tweaks
[3] Disk Cleanup (cache, junk, leftovers...)
[4] Network Adapter Settings (Ethernet)
[5] Interrupt Settings
[6] Enable "Interrupt Routing Lock"
[7] Open BoosterX.exe
[R] Fixes Page (Revert)
```

Individual modules can also be run on their own:

- `checknic.bat` — check the driver type of network adapters
- `devicetweaker.bat` — run the full device/CPU/NIC tuner

## Disclaimer

These scripts modify registry settings, Windows services, and network driver properties. Use at your own discretion:

- Back up your system / create a restore point before applying any tweaks.
- Some presets (e.g., "Gaming PC") disable power saving and interrupt moderation — this may increase power consumption/heat output.
- `pw.exe` (PowerRun) is third-party software not affiliated with this repository; it's used only as a helper launcher with elevated privileges.
