@echo off
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /disable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /disable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /disable
exit
