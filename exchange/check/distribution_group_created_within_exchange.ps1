# Check Active Directory for inproper distribution groups
#
# Author: Christopher Klein <christopher.klein@neos-it.de>

param([string] $ConfigurationFile = "config.psd1")

. $PSScriptRoot\..\..\util.ps1
. $PSScriptRoot\..\..\monitoring\Monitoring.ps1

# import configuration
$config = Load-Configuration "$($ConfigurationFile)"
$monitoring = New-Monitoring $config "distribution_group_created_within_exchange"

# has check been enabled in configuration?
if (!$config.Exchange.DistributionGroups.CheckEnable) {
	$monitoring.AddStatusAndExit(0, "Check not enabled in configuration")
}

# set references from configuration file to local file
## no references required

$groups = Get-AdGroup -Properties msExchArbitrationMailbox -Filter { Name -like "*_DG" } # |?  {  }

$status = 0
$invalidGroups = ""

foreach ($group in $groups) {
	if (-not $group.msExchArbitrationMailbox) {
		$invalidGroups = $invalidGroups + $group.DistinguishedName + ", "
		$status = 1
	}
}

$msg = "OK - All distribution groups created within Exchange Administration UI"

if ($status -ne 0) {
	$msg = "WARN - At least one distribution group not created within Exchange Administration UI. Please delete and recreate them in Exchange: " + $invalidGroups
}

$monitoring.AddStatusAndExit($status, $msg)