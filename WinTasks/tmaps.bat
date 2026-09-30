@echo off
schtasks /change /tn "Microsoft\Windows\Maps\MapsToastTask" /disable
schtasks /change /tn "Microsoft\Windows\Maps\MapsUpdateTask" /disable
schtasks /change /tn "Microsoft\Windows\Location\Notifications" /disable
schtasks /change /tn "Microsoft\Windows\Location\WindowsActionDialog" /disable
exit