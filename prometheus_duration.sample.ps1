# How to use Prometheus exporter
#
# Author: Christopher Klein <christopher.klein@neos-it.de>

$config = @{
	Prometheus = @{
		AdditionalLabels = @{"hostname" = $env:ComputerName; }
		WithHostname = $true
		ExportDirectory = "c:/temp"
		OutputOnConsole = $true
	}
}

. .\monitoring\Prometheus.ps1

$prom = New-Prometheus-Exporter $config "groupnames"

$mBackupStatus = $prom.AddMetric("backup_status", 1)
$mGroupNameConvention = $prom.AddMetric("groupname_convention", 1.100)
$mGroupNameConvention2 = $prom.AddMetric("groupname_convention_2", 0, @{A = "B"; C = "D"})

$timer = $prom.StartTimer("backup_duration", @{name = "system" })

Start-Sleep -Seconds 10

$timer.EndTimer()
	 
$mBackupStatus.SetValue(0)

$prom.Export()