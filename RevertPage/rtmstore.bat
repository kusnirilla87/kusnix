@echo off
schtasks /change /tn "Microsoft\Windows\WS\License Validation" /enable
schtasks /change /tn "Microsoft\Windows\WS\WSRefreshBannedAppsListTask" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\Registration" /enable
schtasks /change /tn "Microsoft\Windows\PushToInstall\LoginCheck" /enable
exit
