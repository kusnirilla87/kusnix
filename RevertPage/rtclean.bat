@echo off
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /enable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /enable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /enable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /enable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /enable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /enable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /enable
exit