# Main class to interact with the monitoring tools (Prometheus, check_mk)
#
# @author Christopher Klein <christopher[dot]klein[at]neos-it[dot]de>

. $PSScriptRoot\CheckMk.ps1
. $PSScriptRoot\Prometheus.ps1

class NeosIT_Monitoring_Fascade
{
	[Hashtable] $configuration = $null
	
	[string] $monitoringNamespace = ""
	
	[object] $checkMkExporter = $null
	
	[object] $prometheusExporter = $null
	
	# Default constructor
	# $monitoringNamespace is used to define the monitoring type
	NeosIT_Monitoring_Fascade($configuration, $monitoringNamespace) {
		$this.monitoringNamespace = $monitoringNamespace
		
		if ($configuration.ContainsKey("Prometheus")) {
			# disable flushing of console output
			$configuration.Prometheus.SkipFlushOnChange = $true
			
			$this.prometheusExporter = New-Prometheus-Exporter $configuration $monitoringNamespace
		}
		
		if ($configuration.ContainsKey("CheckMk")) {
			$this.checkMkExporter = New-CheckMk-Exporter $configuration
		}
	}
	
	# Add new metric (Prometheus) or status (check_mk)
	# $labels are converted to metrics when using check_mk
	[void] AddStatus([string] $metricName, [int] $status, [string] $message, [Hashtable] $labels) {
		if ($this.prometheusExporter) {
			$useLabels = $labels
			$useLabels['message'] = $message
			
			$metric = $this.prometheusExporter.AddMetric($metricName, $status, $useLabels)
		}
	
		if ($this.checkMkExporter) {
			$this.checkMkExporter.AddStatus($metricName, $status, $message, $labels)
		}
	}
	
	[void] AddStatus([string] $metricName, [int] $status, [string] $message) {
		$this.AddStatus($metricName, $status, $message, @{})
	}
	
	[void] Export() {
		if ($this.prometheusExporter) {
			$this.prometheusExporter.Export()
		}
		
		if ($this.checkMkExporter) {
			$this.checkMkExporter.Export()
		}
	}
	
	# Adds the status and exits with 0
	[void] AddStatusAndExit([string] $metricName, [int] $status, [string] $message, [Hashtable] $labels) {
		$this.AddStatus($metricName, $status, $message, $labels);
		$this.Export()
		
		exit 0
	}
	
	# Delegate
	[void] AddStatusAndExit([int] $status, [string] $message, [Hashtable] $labels) {
		$this.AddStatusAndExit($this.monitoringNamespace, $status, $message, $labels);
	}

	# Delegate
	[void] AddStatusAndExit([int] $status, [string] $message) {
		$this.AddStatusAndExit($status, $message, @{})
	}
}

# Forwarding method to create new exporter instance
function New-Monitoring() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Prometheus configuration")]
		[object]
		$configuration,
		
		[parameter(Mandatory = $true, HelpMessage = "Name of monitoring namespace")]
		[string]
		$monitoringNamespace = "my_namespace"
	)
	

	return [NeosIT_Monitoring_Fascade]::new($configuration, $monitoringNamespace);
}