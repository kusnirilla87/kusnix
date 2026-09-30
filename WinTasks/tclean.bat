@echo off
schtasks /change /tn "Microsoft\Windows\ApplicationData\CleanupTemporaryState" /disable
schtasks /change /tn "Microsoft\Windows\ApplicationData\DsSvcCleanup" /disable
schtasks /change /tn "Microsoft\Windows\DiskCleanup\SilentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /disable
schtasks /change /tn "Microsoft\Windows\Setup\SetupCleanupTask" /disable
schtasks /change /tn "Microsoft\Windows\Server Manager\CleanupOldPerfLogs" /disable
schtasks /change /tn "Microsoft\Windows\Servicing\StartComponentCleanup" /disable
schtasks /change /tn "Microsoft\Windows\Wininet\CacheTask" /disable
exit