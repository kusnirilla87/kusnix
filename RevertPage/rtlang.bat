@echo off
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /enable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /enable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /enable
exit