# Validate System backup
# Author: Christopher Klein <christopher.klein@neos-it.de>
# 

param([string] $ConfigurationFile = "config.psd1")

. $PSScriptRoot\..\..\util.ps1
. $PSScriptRoot\..\..\monitoring\Monitoring.ps1
. $PSScriptRoot\..\util.ps1
. $PSScriptRoot\..\validation.ps1

# import configuration
$config = Load-Configuration "$($ConfigurationFile)"
$monitoring = New-Monitoring $config "backup_system"

# has check been enabled in configuration?
if (!$config.Backup.System.CheckEnable) {
	$monitoring.AddStatusAndExit(0, "Check not enabled in configuration")
}

Expect-Backup-System $monitoring $config.Backup.System.Oldest #days
$monitoring.Export()