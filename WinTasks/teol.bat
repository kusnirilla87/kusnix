@echo off
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /disable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /disable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /disable
exit