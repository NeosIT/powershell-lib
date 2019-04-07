# Check Active Directory for inproper named groups without DG/SG suffix
#
# Author: Christopher Klein <christopher.klein@neos-it.de

Param(
	[string] 
	$ConfigurationFile = "config.psd1"
)

. $PSScriptRoot\..\..\util.ps1
. $PSScriptRoot\..\..\monitoring\Monitoring.ps1

# import configuration
$config = Load-Configuration "$($ConfigurationFile)"
$monitoring = New-Monitoring $config "ad_groupname_convention"

# has check been enabled in configuration?
if (!$config.ActiveDirectory.Groups.ForceNamingConvention.CheckEnable) {
	$monitoring.AddStatusAndExit(0, "Check not enabled in configuration")
}

# set references from configuration file to local file
$whitelist = $config.ActiveDirectory.Groups.ForceNamingConvention.Whitelist


## You can create the array by using the following method
# $groups = Get-Adgroup -Filter { Name -notLike "*_SG" -and Name -notlike "*_DG"} |?  {($_.distinguishedname -notlike '*DSADMINS*') -or ($_.DistinguishedName -notlike "*Builtin*") -or ($_.DistinguishedName -notlike "*Microsoft Exchange*")}
# foreach ($group in $groups) {
#	write-host ('	"{0}",' -f $($group.DistinguishedName))
# }

$groups = Get-Adgroup -Filter { Name -notLike "*_SG" -and Name -notlike "*_DG"} |?  {($_.distinguishedname -notlike '*DSADMINS*') -or ($_.DistinguishedName -notlike "*Builtin*") -or ($_.DistinguishedName -notlike "*Microsoft Exchange*")}

$status = 0
$invalidGroups = ""

foreach ($group in $groups) {
	if ($whitelist -notcontains $group.DistinguishedName) {
		$status = 1;
		# group names can not be concatted by using a quote and/or semicolon because of check_mk expected output
		$invalidGroups = $invalidGroups + $group.DistinguishedName + ", "
	}
}

$msg = "OK - Group names are valid"

if ($status -ne 0) {
	$msg = "WARN - Invalid group names found (not having SG/DG suffix): " + $invalidGroups
}

$monitoring.AddStatusAndExit($status, $msg, @{ invalid_groups = $invalidGroups })