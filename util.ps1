# Generic utilities
#
# @author Christopher Klein <christopher[dot]klein[at]neos-it[dot]de>

# Load given configuration file
function Load-Configuration() {
	Param(
		[parameter(Mandatory=$True, HelpMessage="Absolute path to configuration file")]
		[string]
		$absolutePath		
	)
	
	if (!(Test-Path $absolutePath)) {
		Write-Error "Configuration file $($absolutePath) does not exist. Maybe you have forget to copy the template configuration?"
		exit
	}
	
	$directory = Split-Path -Path $absolutePath
	$configFile = Split-Path -Path $absolutePath -Leaf
	
	$config = Import-LocalizedData -BaseDirectory $directory -FileName $configFile
	
	return $config
}

function Notify-Start($log) {
}

function Notify($log) {
}

function Notify-End($log) {
}
