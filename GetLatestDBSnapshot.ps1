#
# GetLatestDBSnapshot.ps1
#
param (
	[Parameter(Mandatory=$true)][string]$AWSAccessKey = "",
	[Parameter(Mandatory=$true)][string]$AWSSecret = "",
    [string]$Region = "us-west-2",
    [Parameter(Mandatory=$true)][string]$DBInstanceName = ""
 )

#setup
Set-AWSCredentials -AccessKey $AWSAccessKey -SecretKey $AWSSecret

#check arguments
if (($DBInstanceName -eq $null) -or ($DBInstanceName.Length -eq 0)) {
	Write-Host ("A valid DBInstanceIdentifier was not provided. Cannot return a snapshot Id")
	exit 1
}

#find latest snapshot ID for specified restore database
$snapshots = Get-RDSDBSnapshot -Region $Region -DBInstanceIdentifier $DBInstanceName
if ($snapshots.Count -gt 0) {
	$mostRecentCreated = Get-Date -Year 2000

	foreach($snapshot in $snapshots) {
		if ($mostRecentCreated -lt (Get-Date $snapshot.SnapshotCreateTime)) {
			$mostRecentCreated = (Get-Date $snapshot.SnapshotCreateTime)
			$RDSSnapshotId = $snapshot.DBSnapshotIdentifier
		}
	}

	Write-Host ("Most recent snapshot for database "+$DBInstanceName+" is snapshot "+$RDSSnapshotId)
	Write-Output ($RDSSnapshotId)
} else {
	Write-Output ("No snapshots found for DBInstanceIdentifier: "+$DBInstanceName)
	exit 1
}