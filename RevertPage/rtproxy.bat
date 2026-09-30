@echo off
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /enable
exit