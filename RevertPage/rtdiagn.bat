@echo off
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
exit