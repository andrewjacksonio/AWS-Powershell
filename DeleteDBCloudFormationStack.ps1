#
# DeleteDBCloudFormationStack.ps1
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
	Write-Host ("Invalid DBInstanceIdentifier provided. Cannot continue.")
	exit 1
}

#check if database exists - if database exists, delete CFN stack
$DBInstance = Get-RDSDBInstance -Region $Region $DBInstanceName
if ($DBInstance -ne [Array]) #will be empty array if no instance found
{
	#delete stack that built database
	Write-Output ("Deleting CloudFormation stack: "+$DBInstanceName)
	Remove-CFNStack -Region $Region -StackName $DBInstanceName -Force

	Do { #loop until database is gone
		#display progress
		Write-Output ("Waiting for database deletion... Database status: "+$DBInstance.DBInstanceStatus)

        start-sleep -seconds 20

		$DBInstance = $null
		$DBInstance = Get-RDSDBInstance -Region $Region $DBInstanceName
	} Until ($DBInstance -eq $null)

	Write-Output ("Cloud Formation stack deletion complete.")
}