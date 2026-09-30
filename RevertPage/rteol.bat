@echo off
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify" /enable
schtasks /change /tn "Microsoft\Windows\Setup\EOSNotify2" /enable
schtasks /change /tn "Microsoft\Windows\WindowsBackup\ConfigNotification" /enable
exit