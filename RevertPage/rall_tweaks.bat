@echo off
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /enable
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /enable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /enable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /enable
schtasks /change /tn "Microsoft\Windows\Chkdsk\ProactiveScan" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /enable
schtasks /change /tn "Microsoft\Windows\Diagnosis\Scheduled" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /enable
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\Diagnostics" /enable
schtasks /change /tn "Microsoft\Windows\DiskFootprint\StorageSense" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /enable
schtasks /change /tn "Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /enable
schtasks /change /tn "Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\ServerManager" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierdaily" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\appuriverifierinstall" /enable
schtasks /change /tn "Microsoft\Windows\WindowsColorSystem\Calibration Loader" /enable
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /enable
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /enable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /disable
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /enable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /enable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /enable
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackgroundUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\BackupTask" /enable
schtasks /change /tn "Microsoft\Windows\SettingSync\NetworkStateChangeTask" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /enable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /enable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /enable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /enable
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /enable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /enable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /enable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /enable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /enable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /enable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /enable
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f
DISM.exe /Online /Set-ReservedStorageState /State:Enabled
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringFlags" /f
start "" "c:\kusnix\wintasks\fso.reg
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume" /v value /t REG_DWORD /d 0 /f >nul
exit