@echo off
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /enable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /enable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /enable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /enable
exit