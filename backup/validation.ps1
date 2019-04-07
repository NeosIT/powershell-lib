# Primary check_mk functions for checking that the backups has been run

# Expect that the system backup has been run in the last days
# It writes directly the expected chec_mk output
function Expect-Backup-System() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Monitoring fascade")]
		[NeosIT_Monitoring_Fascade]
		$monitoring,
		
		[parameter(Mandatory = $false, HelpMessage = "Days when the last backup should have been done, defaults to 2 days")]
		[int]
		$maxOldestBackupInDays = 2
	)
	
	$dateBackupNewerThan = Get-Date
	$dateBackupNewerThan = $dateBackupNewerThan.AddDays(-1 * $maxOldestBackupInDays)

	$wbSummary = Get-WBSummary
	$dateLastBackup = $wbSummary.LastSuccessfulBackupTime

	# defensive programming, assume failure
	$status = "2"
	$statusMsg = "CRITICAL - LastBackupResultHR: $($wbSummary.LastBackupResultHR), LastBackupResultDetailedHR: $($wbSummary.LastBackupResultDetailedHR)"

	if ($dateLastBackup -lt $dateBackupNewerThan) {
		# we had a failure and backup is too old
		$statusMsg = $statusMsg + ", Last succesful backup on $($dateLastBackup) ($($dateBackupNewerThan))."
	}
	else {
		if ($wbSummary.LastBackupResultHR -eq 0 -And $wbSummary.LastBackupResultDetailedHR -eq 0) {
			# everything is fine
			$status = "0"
			$statusMsg = "OK - Last backup on $($dateLastBackup), younger than ($($dateBackupNewerThan))."
		}
	}

	$monitoring.AddStatus("wbe_backup", $status, $statusMsg)
}

function Assume-Directory-Has-Min-Size() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Monitoring fascade")]
		[object]
		$monitoring,
		
		[parameter(Mandatory = $true, HelpMessage = "Directory which should contain the given size")]
		[string]
		$directory,

		[parameter(Mandatory = $false, HelpMessage = "Minimum total size of directory in MByte")]
		[int]
		$minSize = 100 # megabyte
	)
	
	$dirInfo = (Get-ChildItem $directory -Recurse | Measure-Object -Property length -sum)
	$sizeInMegaByte = ($dirInfo.sum / 1MB)
	$status = "1"
	
	if ($sizeInMegaByte -gt $minSize) {
		$status = "0"
		$msg = "OK - Backup directory has positive size"
	}
	else {
		$msg = "WARN - Backup directory has not assumed minimum size of {0:N2} MByte but {1:N2} MByte" -f $minSize, $sizeInMegaByte
	}

	$monitoring.AddStatus("total_size_$($directory)", $status, $msg, @{ min_size = $minSize; size = $sizeInMegaByte })
}

function Assume-Directory-Entries() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Monitoring fascade")]
		[NeosIT_Monitoring_Fascade]
		$monitoring,
		
		[parameter(Mandatory = $true, HelpMessage = "Directory which should contain entries")]
		[string]
		$directory,
		
		[parameter(Mandatory = $false, HelpMessage = "Minimum total entries, defaults to 14")]
		[int]
		$min = 14,
		
		[parameter(Mandatory = $false, HelpMessage = "Maximum total entries, defaults to 16")]
		[int]
		$max = 16
	)
	
	$total = (Get-ChildItem $directory | Measure-Object).Count
	
	$status = "1"
	
	if ($total -ge $min -and $total -le $max) {
		$status = "0"
		$msg = "OK - Number of top-level directory entries are available"
	}
	else {
		$msg = "WARN -"
		
		if ($total -lt $min) {
			$msg += " Only $($total) entries available. Expected $($min). Backup not run?"
		}
		
		if ($total -gt $max) {
			$msg += " $($total) entries available. Expected max $($max). This is too much. Did clean-up not run?"
		}
	}
	
	$monitoring.AddStatus("number_of_toplevel_entries_$($directory)", $status, $msg, @{ min = $min; max = $max })
}

function Expect-Last-Change() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Monitoring fascade")]
		[NeosIT_Monitoring_Fascade]
		$monitoring,
		
		[parameter(Mandatory = $true, HelpMessage = "Directory in which a change should have happened")]
		[string]
		$directory,

		[parameter(Mandatory = $false, HelpMessage = "Youngest age in days, defaults to 2 days")]
		[int]
		$youngest = 2
	)
	
	$youngestItem = Get-ChildItem -Path $directory | Sort-Object CreationTime -Descending | Select-Object -First 1
	$ts = New-Timespan -days $youngest
	
	$status = "2"
	$msg = ""
	
	if (((Get-Date) - $youngestItem.CreationTime) -lt $ts) {
		$status = "0"
		$msg = "OK - Directory has been changed on $($youngestItem.CreationTime)"
	} else {
		$msg = "CRITICAL - Directory has not been changed in $($youngest) days. Youngest item is of $($youngestItem.CreationTime)"
	}

	$monitoring.AddStatus("last_change_$($directory)", $status, $msg, @{ youngest = $youngest })
}