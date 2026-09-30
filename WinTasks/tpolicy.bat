@echo off
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /disable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /disable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /disable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /disable
exit