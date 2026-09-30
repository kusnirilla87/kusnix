@echo off
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTask" /disable
schtasks /change /tn "Microsoft\XblGameSave\XblGameSaveTaskLogon" /disable
exit