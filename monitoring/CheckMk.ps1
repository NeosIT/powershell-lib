# Exporter for check_mk
#
# Author: Christopher Klein <christopher.klein@neos-it.de>
class NeosIT_Monitoring_CheckMk_Exporter
{
	# status entries
	[array] $entries = @()
	
	# configuration object
	[object] $configuration = $null
	
	# constructor
	NeosIT_Monitoring_CheckMk_Exporter([object] $configuration) {
		$this.configuration = $configuration
	}
	
	# Add a status for the given check
	# Each of the labels is (if it is a numeric type) converted to a metric
	[void] AddStatus($checkName, $status, $message, $labels) {
		$metrics = @{}
		
		foreach ($label in $labels.Keys) {
			$value = $labels[$label]
		
			# only accept numeric metrics
			# @see https://stackoverflow.com/a/10928171
			if ($value -is [byte]  -or $value -is [int16]  -or $value -is [int32]  -or $value -is [int64] -or $value -is [sbyte] -or $value -is [uint16] -or $value -is [uint32] -or $value -is [uint64] -or $value -is [float] -or $value -is [double] -or $value -is [decimal]) {
				$metrics[$label] = $value
			}
		}
		
		$this.entries += @{ name = $checkName; status = $status; message = $message; metrics = $metrics }
	}
	
	# Export the check and its metrics by writing it directly to the host
	[void] Export() {
		foreach ($entry in $this.entries) {
			$metrics = @()
			$useMetrics = ""
			
			# build metrics with format $metric1=$value|$metric2=$value
			if ($entry.metrics.Count -gt 0) {
				foreach ($key in $entry.metrics.Keys) {
					$metrics += "$($key)=$($entry.metrics[$key])"
				}
				
				$useMetrics = $metrics -join "|"
			}
			
			Write-Host "$($entry.status) $($entry.name) $($useMetrics) - $($entry.message)"
		}
	}
}

# Forwarding method to create new exporter instance
function New-CheckMk-Exporter() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Configuration")]
		[object]
		$configuration
	)
	
	return [NeosIT_Monitoring_CheckMk_Exporter]::new($configuration);
}