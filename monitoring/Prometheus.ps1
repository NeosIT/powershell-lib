# Prometheus PowerShell metrics exporter
# You can use this class to collect metrics via PowerShell to let them collect bei Prometheus' wmi_exporter
#
# @author Christopher Klein <christopher[dot]klein[at]neos-it[dot]de>
class NeosIT_Monitoring_Prometheus_Metric {
	# Name of this metric
	[string] $name
	
	# Value of this metric
	[decimal] $value
	
	# Whole label string
	[string] $labels
	
	# Timestamp of the creation of this metric
	[int] $timestamp = 0
	
	# Reference to PrometheusExporter
	[object] $exporter = $null
	
	# Default constructor for simple metric
	NeosIT_Monitoring_Prometheus_Metric([string] $name, [decimal] $value, [string] $labels, [object] $exporter) {
		$this.name = $name
		$this.labels = $labels
		$this.timestamp = [int][double]::Parse((Get-Date -UFormat %s))

		if ($exporter -ne $null) {
			$this.exporter = $exporter
			$this.exporter.metrics += $this
		}
		
		$this.SetValue($value)
	}
	
	# Constructor for timer, the current timestamp is used as metric value
	NeosIT_Monitoring_Prometheus_Metric([string] $name, [string] $labels, [object] $exporter) {
		$this.name = $name
		$this.labels = $labels
		$this.timestamp = [int][double]::Parse((Get-Date -UFormat %s))
		
		if ($exporter -ne $null) {
			$this.exporter = $exporter
			$this.exporter.metrics += $this
		}
		
		$this.SetValue($this.timestamp)
	}
	
	# Ends the current timer and flushes the output
	[void] EndTimer() {
		$this.EndTimer($true)
	}
	
	# Ends the current timer
	[void] EndTimer([boolean] $flush) {
		$useValue = [int][double]::Parse((Get-Date -UFormat %s)) - $this.timestamp
		
		$this.SetValue([decimal]$useValue, $flush)
	}

	# Sets the value of this metric and flushes the output
	[void] SetValue([decimal] $value) {
		$this.SetValue($value, $true)
	}
	
	# Sets the value of this timer
	[void] SetValue([decimal] $value, [boolean] $flush) {
		$this.value = $value

		if ($flush -eq $true) {
			if ($this.exporter -ne $null) {
				$this.exporter.ValueChanged()
			}
		}
	}
}

class NeosIT_Monitoring_Prometheus_Exporter {
	# Generic Prometheus configuration
	# This must be a hashtable containing the .Prometheus namespace
	[object] $configuration
	
	# Name of file to use for exports without the file extensions
	[string] $exportFile
	
	# Additional labels to export for every collected metric
	[array] $additionalLabels
	
	# defined PrometheusMetrics
	[array] $metrics = @()
	
	# Constructor
	NeosIT_Monitoring_Prometheus_Exporter([object] $configuration, [string] $exportFile) {
		$this.configuration = $configuration
		$this.exportFile = $exportFile
		# For performance reason we cache the default labels and timestamp
		$this.additionalLabels = $this.CreateLabels($this.ConfigurationValue("AdditionalLabels"))
	}
	
	###
	### Metrics
	### 

	# Add metric with given name and value and additional labels to the collection
	[NeosIT_Monitoring_Prometheus_Metric] AddMetric([string] $name, [decimal] $value, [Hashtable] $labels) {
		$metric = $this.CreateMetric($name, $value, $labels)
		
		return $metric
	}
	
	# Add metric without any labels; default labels will still be applied
	[NeosIT_Monitoring_Prometheus_Metric] AddMetric([string] $name, [decimal] $value) {
		return $this.AddMetric($name, $value, $null)
	}
	
	# Create new NeosIT_Monitoring_Prometheus_Metric instance
	[NeosIT_Monitoring_Prometheus_Metric] CreateMetric([string] $name, [decimal] $value, [Hashtable] $labels) {
		if ($value -eq $null) {
			$value = 0
		}

		return [NeosIT_Monitoring_Prometheus_Metric]::new($name, $value, $this.CreateLabelString($labels), $this)
	}
	
	###
	### Timer
	###
	
	# Create new NeosIT_Monitoring_Prometheus_Metric instance by calling the specific constructor
	[NeosIT_Monitoring_Prometheus_Metric] StartTimer([string] $name, [Hashtable] $labels) {
		$metric = [NeosIT_Monitoring_Prometheus_Metric]::new($name, $this.CreateLabelString($labels), $this)
		
		return $metric
	}
	
	###
	### Labels
	###
	
	[string] CreateLabelString([Hashtable] $labels) {
		$useLabels = $this.additionalLabels
		$useLabels += $this.CreateLabels($labels)
		
		return $useLabels -join ","
	}
	
	# Based upon the given label hashtable an array is generated for each key/value pair
	# $labels can be null
	[array] CreateLabels([Hashtable] $labels) {
		$r = @()
		
		if ($labels -ne $null) {
			foreach ($key in $labels.keys) {
				$r += $this.CreateLabel($key, $labels[$key])
			}
		}
		
		return $r;
	}
	
	# Create a label key-value pair
	[string] CreateLabel([string]$key, [string]$value) {
		return $key + '="' + $($value) + '"'
	}
	
	# Retrieve a configuration key from the .Prometheus configuration namespace
	[object] ConfigurationValue($key) {
		if ($this.configuration.ContainsKey("Prometheus") -eq $true) {
			if ($this.configuration.Prometheus.ContainsKey($key)) {
				return $this.configuration.Prometheus[$key];
			}
		}
		
		return $null
	}
	
	[void] ValueChanged() {
		$skipFlushOnChange = $this.ConfigurationValue("SkipFlushOnChange")
		
		if (!$skipFlushOnChange) {
			$this.Export()
		}
	}
	
	# Exports any collected metric into the export directory
	# If .Prometheus.ExportDirectory has not been set, no .prom file is created
	[void] Export() 
	{
		$exportDirectory = $this.configurationValue("ExportDirectory")
		
		$useMetrics = @()

		foreach ($metric in $this.metrics) {
			# metric timestamp is explicitly not exported as it is not supported in .prom files
			$useMetrics += "$($metric.name){$($metric.labels)} $($metric.value)"
		}
		
		if ($exportDirectory -and !(Test-Path -Path $exportDirectory)) {
			Write-Error "Prometheus output directory $($this.configuration.Prometheus.ExportDirectory) does not exist or is not writable"
		}
		else {
			Set-Content -Path "$($this.configuration.Prometheus.ExportDirectory)/$($this.exportFile).prom" -Value $useMetrics
		}
		
		if ($this.ConfigurationValue("OutputOnConsole") -eq $true) {
			Write-Host $useMetrics
		}
	}
}

# Forwarding method to create new exporter instance
function New-Prometheus-Exporter() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Prometheus configuration")]
		[object]
		$configuration,
		
		[parameter(Mandatory = $true, HelpMessage = "Name of file prefix without .prom file extension")]
		[string]
		$metricFilePrefix = "metric"
	)
	
	return [NeosIT_Monitoring_Prometheus_Exporter]::new($configuration, $metricFilePrefix);
}