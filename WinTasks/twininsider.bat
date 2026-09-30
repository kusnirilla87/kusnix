@echo off
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /disable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /disable
exit