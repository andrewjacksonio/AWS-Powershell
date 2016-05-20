#
# CreateDBCloudFormationStack.ps1
#
param (
	[Parameter(Mandatory=$true)][string]$AWSAccessKey = "",
	[Parameter(Mandatory=$true)][string]$AWSSecret = "",
    [string]$Region = "us-west-2",
    [Parameter(Mandatory=$true)][string]$DBInstanceName = "",
	[Parameter(Mandatory=$true)][string]$RDSSnapshotId = "",
	[Parameter(Mandatory=$true)][string]$StackTemplatePath = ""
 )

#setup
Set-AWSCredentials -AccessKey $AWSAccessKey -SecretKey $AWSSecret

#check arguments
if (($DBInstanceName.Length -eq 0)) {
	Write-Host ("Invalid DBInstanceIdentifier provided. Cannot continue.")
	exit 1
}

if (($StackTemplatePath.Length -eq 0)) {
	Write-Host ("Invalid Cloud Formation template path provided. Cannot continue.")
	exit 1
}

$StackTemplateStr = Get-Content $StackTemplatePath -Raw 

#Add/Renew CFN stack for database
Write-Host ("Creating CloudFormation stack "+$DBInstanceName)
$result = New-CFNStack -Region $Region -StackName $DBInstanceName -TemplateBody $StackTemplateStr -Parameter @{ ParameterKey="DBInstanceName";ParameterValue=$DBInstanceName},@{ParameterKey="RDSSnapshotId";ParameterValue=$RDSSnapshotId}

Do { #loop until stack created
	start-sleep -seconds 20
	$CFNStack = Get-CFNStack -Region $Region -StackName $DBInstanceName

	#display progress
	Write-Host ("Stack creating... StackStatus: "+$CFNStack.StackStatus)
} Until ($CFNStack.StackStatus -eq "CREATE_COMPLETE")

Write-Host ("CloudFormation creation complete. StackId: "+$result)