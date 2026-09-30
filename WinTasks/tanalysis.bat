@echo off
schtasks /change /tn "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /change /tn "Microsoft\Windows\RAC\RacTask" /disable
schtasks /change /tn "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" /disable
schtasks /change /tn "Microsoft\Windows\AppListBackup\Backup" /disable
exit