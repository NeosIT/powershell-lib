# Check Backup of Exchange 2013 and later
#
# Author: Christopher Klein <christopher.klein@neos-it.de>

Param(
	[string] 
	$ConfigurationFile = "config.psd1"
)

. $PSScriptRoot\..\..\util.ps1
. $PSScriptRoot\..\..\monitoring\Monitoring.ps1

# import configuration
$config = Load-Configuration "$($ConfigurationFile)"
$monitoring = New-Monitoring $config "exchange_full_backup"

# has check been enabled in configuration?
if (!$config.Backup.Exchange.CheckEnable) {
	$monitoring.AddStatusAndExit(0, "Check not enabled in configuration")
}

# set references from configuration file to local file
$maxOldestBackupInDays = $config.Backup.Exchange.Oldest

## DO NOT MODIFY AFTER THIS LINE
# E2010 is also valid for 2013 and newer
Add-PSSnapIn Microsoft.Exchange.Management.PowerShell.E2010
# create reference date
$dateBackupNewerThan = Get-Date
$dateBackupNewerThan = $dateBackupNewerThan.AddDays(-1 * $maxOldestBackupInDays).ToShortDateString()

$wbSummary = Get-MailboxDatabase -Status
$dateLastBackup = $wbSummary.LastFullBackup

# defensive programming, assume failure
$status = "2"
$statusMsg = "CRITICAL - Last full backup: $($dateLastBackup)"

if ($dateLastBackup.ToShortDateString() -gt $dateBackupNewerThan) {
	# everything is fine
	$status = "0"
	$statusMsg = "OK - Last full backup on $($dateLastBackup)"
}

$monitoring.AddStatusAndExit($status, $statusMsg)