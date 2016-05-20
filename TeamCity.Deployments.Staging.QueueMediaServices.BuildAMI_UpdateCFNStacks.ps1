##vars
$AWSAccessKey="%AWSAccessKey%"
$AWSSecret="%secure:teamcity.password.secure:teamcity.password.AWSSecret%"
$region = "ap-southeast-1"
$instanceId = "i-8f065b01"
$imageName = "ST-Q-MEDIA-BUILD-"+"%system.build.number%"
$CFNLaunchConfig = "ST-IC-MEDIA-LC"
$instanceName = "ST-IC-AUTOSCALE-SG"
$buildNumber = "%system.build.number%"
$SQSregion = "us-west-2"
$SQSUrl = "https://sqs.us-west-2.amazonaws.com/130075576898/Staging_QueuedMediaServices_Deployment_Request_Logs"

#setup
import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
Set-AWSCredentials -AccessKey $AWSAccessKey -SecretKey $AWSSecret

$timeout = new-timespan -Minutes 60
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout)
{
    if(!($deployComplete))
    {
        $SQSMessage = Receive-SQSMessage -Region $SQSregion -QueueUrl $SQSUrl

        if($SQSMessage)
        {
            if($SQSMessage.Body -like "*"+$instanceName+"*") 
            {
                if($SQSMessage.Body -like "*"+$buildNumber+"-COMPLETED*") 
                {
                    Write-Output ("Instance deploy success.")
                    $amiId = New-EC2Image -Region $region -InstanceId $instanceId -Name $imageName -NoReboot 1
                    Clear-SQSQueue -Region $SQSregion -QueueUrl $SQSUrl
                    $deployComplete = 1
                }
                if($SQSMessage.Body -like "*"+$buildNumber+"-FAILED*")
                {
                    Write-Output ("Deployment to instance failed.")
                    Clear-SQSQueue -Region $SQSregion -QueueUrl $SQSUrl
                    ##teamcity[buildStatus status='FAILURE' ]
                    exit 1
                }
            }

            #message not for instance or not complete or failed - delete & move to next.
            Remove-SQSMessage -Region $SQSregion -QueueUrl $SQSUrl -ReceiptHandle $SQSMessage.ReceiptHandle -Force
            Write-Output ("A message was removed.")
        }
        Write-Output ("Polling for results...")
        start-sleep -seconds 15
    }
    else
    {
        $EC2Image = Get-EC2Image -Region $region -ImageId $amiId
        if ($EC2Image.State -eq "available")
        {
            Update-CFNStack -Region $region -StackName $CFNLaunchConfig -UsePreviousTemplate 1 -Parameter @{ ParameterKey="AmiId";ParameterValue="$amiId" }
            start-sleep -seconds 20
            $LaunchConfig = Get-CFNStackResourceSummary -Region $region -StackName $CFNLaunchConfig
            Update-CFNStack -Region $region -StackName ST-IC-AUTOSCALE-SG -UsePreviousTemplate 1 -Parameter @{ ParameterKey="LaunchConfig";ParameterValue=$LaunchConfig.PhysicalResourceId }
            exit 0
        }

        Write-Output ("AMI is building...")
        start-sleep -seconds 15
    }
}
 
Write-Host("Timed out waiting for "+$instanceName+" build "+$buildNumber+" result")
##teamcity[buildStatus status='FAILURE' ]
exit 1