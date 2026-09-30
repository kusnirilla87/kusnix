@echo off
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" /disable
schtasks /change /tn "Microsoft\Windows\Data Integrity Scan\Data Integrity Check And Scan" /disable
schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /disable
exit
