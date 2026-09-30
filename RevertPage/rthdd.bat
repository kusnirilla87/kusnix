@echo off
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /enable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /enable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /enable
exit
