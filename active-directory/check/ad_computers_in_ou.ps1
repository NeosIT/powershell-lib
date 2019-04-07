# Check Active Directory for inproper location of computers
#
# Author: Christopher Klein <christopher.klein@neos-it.de>

Param(
	[string] $ConfigurationFile = "config.psd1"
)

. $PSScriptRoot\..\..\util.ps1
. $PSScriptRoot\..\..\monitoring\Monitoring.ps1

# import configuration
$config = Load-Configuration "$($ConfigurationFile)"
$monitoring = New-Monitoring $config "ad_computer_ou_location"

# has check been enabled in configuration?
if (!$config.ActiveDirectory.Computer.CheckEnable) {
	$monitoring.AddStatusAndExit(0, "Check not enabled in configuration")
}

# set references from configuration file to local file
$whitelist = $config.ActiveDirectory.Computer.Whitelist
$computerBaseDN = $config.ActiveDirectory.Computer.BaseDN

$computers = Get-ADComputer -Filter 'ObjectClass -eq "Computer"'
$status = 0
$invalidComputers = ""

foreach ($computer in $computers) {
	if ($whitelist -notcontains $computer.DistinguishedName) {
		if (-not $computer.DistinguishedName.endsWith($computerBaseDN)) {
			$status = 1;
			$invalidComputers = $invalidComputers + $computer.DistinguishedName + "; "
		}
	}
}

$msg = "OK - Computers are located in expected Active Directory OUs"

if ($status -ne 0) {
	$msg = "WARN - Invalid computer OU location found. All must be located in '$($computerBaseDN)'. See https://wiki.neos-it.de/confluence/pages/viewpage.action?pageId=138903904: " + $invalidComputers
}

$monitoring.AddStatusAndExit($status, $msg)