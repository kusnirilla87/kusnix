@echo off
schtasks /change /tn "Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" /disable
exit
