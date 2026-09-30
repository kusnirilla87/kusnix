@echo off
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)" /enable
schtasks /change /tn "Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)" /enable
schtasks /change /tn "Microsoft\Windows\User Profile Service\HiveUploadTask" /enable
schtasks /change /tn "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" /enable
exit