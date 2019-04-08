# Execute all checks
#
# Author: Christopher Klein <christopher.klein@neos-it.de

Param(
	[string] 
	$ConfigurationFile = "config.psd1"
)

. $PSScriptRoot\active-directory\check\ad_computers_in_ou.ps1 -ConfigurationFile $ConfigurationFile
. $PSScriptRoot\active-directory\check\ad_groupname_convention.ps1 -ConfigurationFile $ConfigurationFile
. $PSScriptRoot\backup\check\backup_system_present.ps1 -ConfigurationFile $ConfigurationFile
. $PSScriptRoot\exchange\check\distribution_group_created_within_exchange.ps1 -ConfigurationFile $ConfigurationFile
. $PSScriptRoot\exchange\check\exchange_backup_present.ps1 -ConfigurationFile $ConfigurationFile
