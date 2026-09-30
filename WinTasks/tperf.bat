@echo off
schtasks /change /tn "Microsoft\Windows\Maintenance\WinSAT" /disable
exit