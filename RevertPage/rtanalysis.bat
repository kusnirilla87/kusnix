@echo off
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /enable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /enable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /enable
exit