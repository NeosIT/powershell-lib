# How to use monitoring fascade
#
# Author: Christopher Klein <christopher.klein@neos-it.de>

$config = @{
	# Enable check_mk
	CheckMk = @{
	}
	
	Prometheus = @{
		AdditionalLabels = @{"hostname" = $env:ComputerName; }
		WithHostname = $true
		ExportDirectory = "c:/temp"
		OutputOnConsole = $true
	}
}

. .\monitoring\Monitoring.ps1
. .\backup\validation.ps1

$monitoring  = New-Monitoring @{ CheckMk = @{} } "my_namespace"
Assume-Directory-Has-Min-Size $monitoring "C:\temp\bla"
$monitoring.Export()
