# Mount the SMB directory which contains the local backups for this server
function Mount-Backup-SMB() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "UNC drive which is mounted locally")]
		[string]
		$targetDrive,
		
		[parameter(Mandatory = $true, HelpMessage = "Path to UNC share like \\my_host")]
		[string]
		$uncShare,
		
		[parameter(Mandatory = $true, HelpMessage = "Username for UNC share")]
		[string]
		$uncUsername,
		
		[parameter(Mandatory = $true, HelpMessage = "Password for UNC share")]
		[string]
		$uncPassword
	)
	
	Write-Host "Mounting SMB backup share $($uncShare) (User: $($uncUsername)) to local drive $($targetDrive)"
	
	$secUncPassword = ConvertTo-SecureString "$uncPassword" -AsPlainText -Force
	$uncCredential = New-Object System.Management.Automation.PSCredential($uncUsername, $secUncPassword)

	# the network drive is only available in this script session and is disconnected straight after the script has ended
	if (get-psdrive | where-object -FilterScript {$_.Name -eq $targetDrive}) { 
		# Write-Host "Drive $targetDrive has been alrady mounted"
	} else {
		# Drive must be made available with "-Scropt global" or it is not accesible outside this PowerShell session
		$res = New-PSDrive -Name $targetDrive -PSProvider FileSystem -Root $uncShare -Credential $uncCredential -Persist -Scope global
		# Write-Host "Mounted $uncShare on drive $targetDrive"
	}

	# create reference to target dir
	$hostDir = Host-Dir($targetDrive)
	
	$res = New-Item -ItemType Directory -Force -Path $hostDir

	return "$hostDir"
}

# Get full drive path to SMB share like s:\my_hostname. "my_hostname" is replaced by the current hostname
function Host-Dir() {
	Param(
		[parameter(Mandatory=$True, HelpMessage="UNC drive")]
		[string]
		$targetDrive
	)

	$hostname = $env:computername
	
	return "$($targetDrive):\$($hostname)"
}

# Umount mounted SMB backup share
function Unmount-Backup-SMB() {
	Param(
		[parameter(Mandatory=$True, HelpMessage="UNC drive to unmount")]
		[string]
		$drive
	)
	
	## Cleanup
	Remove-PSDrive -Name $drive
	Write-Host "Target $drive removed"
}

# Cleanup backup directory with all files and folders older than given days
function Cleanup-Backup-SMB() {
	Param(
		[parameter(Mandatory=$True, HelpMessage="Target drive where SMB/Data backups are stored")]
		[string]
		$targetDrive,
		
		[parameter(Mandatory=$False, HelpMessage="Maximum days to keep backups, by default this is set to 5 days")]
		[string]
		$maximumDays = 5
	)
	
	$hostDir = Host-Dir($targetDrive)
	
	$limit  = (Get-Date).AddDays(-1 * $maximumDays)
	Write-Host "Purging all files and directories from $hostDir older than $maximumDays days"

	### Delete files older than the $limit.
	Get-ChildItem -Path $hostDir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force

	### Delete any empty directories left behind after deleting the old files.
	Get-ChildItem -Path $hostDir -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
}

# Execute a VSS full backup of the system with the given drives
function Backup-System() {
	Param(
		[parameter(Mandatory = $true, HelpMessage = "Target drive where to store Windows Backups")]
		[string]
		$targetDrive,
		
		[parameter(Mandatory = $true, HelpMessage = "List of source drives to backup")]
		[array]
		$sourceDrives
	)
	
	$policy = New-WBPolicy
	Add-WBSystemState $policy
	Add-WBBareMetalRecovery $policy
	Set-WBVssBackupOptions -Policy $policy -VssFullBackup

	### add volume
	foreach ($drive in $sourceDrives) {
		Write-Host "Adding drive $drive to full backup"
		$volume = Get-WBVolume -VolumePath $drive
		Add-WBVolume -Policy $policy -Volume $volume
	}

	### Define target drive where to store full backup
	$backupLocation = New-WBBackupTarget -VolumePath $targetDrive
	Add-WBBackupTarget -Policy $policy -Target $backupLocation

	Write-Host "Starting new volume backup to $targetDrive"
	Start-WBBackup -Policy $policy
}
