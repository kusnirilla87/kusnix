@echo off
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /disable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /disable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /disable
start "" "C:\kusnix\WinTasks\pw.exe" cmd.exe /c "C:\kusnix\WinTasks\msync.bat"
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
start "" "c:\kusnix\wintasks\fse.reg"
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume" /v value /t REG_DWORD /d 1 /f >nul
exit