@echo off
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
exit