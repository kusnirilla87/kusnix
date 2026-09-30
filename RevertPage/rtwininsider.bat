@echo off
schtasks /change /tn "Microsoft\Windows\Flighting\OneSettings\RefreshCache" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\BootstrapUsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" /enable
schtasks /change /tn "Microsoft\Windows\Flighting\FeatureConfig\UsageDataReceiver" /enable
exit