@echo off
schtasks /change /tn "Microsoft\Windows\International\Synchronize Language Settings" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Installation" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources" /disable
schtasks /change /tn "Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" /disable
schtasks /change /tn "Microsoft\Windows\MUI\LPRemove" /disable
exit