@echo off
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /enable
exit
