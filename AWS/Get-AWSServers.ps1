
$output = foreach ($Region in (Get-AWSRegion)) 
{
  $Instances = (Get-EC2Instance -Region $Region.Region).instances 
  $VPCS = Get-EC2Vpc -Region $Region.Region
  foreach ($VPC in $VPCS) 
  {
    $Instances |
    Where-Object -FilterScript {
      $_.VpcId -eq $VPC.VpcId
    } |
    ForEach-Object -Process {
      New-Object -TypeName PSObject -Property @{
        'VpcId'         = $_.VpcId
        'VPCName'       = ($VPC.Tags | Where-Object -FilterScript {$_.Key -eq 'Name'}).Value
        'InstanceId'    = $_.InstanceId
        'InstanceType'  = $_.InstanceType
        'InstanceName'  = ($_.Tags | Where-Object -FilterScript {$_.Key -eq 'Name' }).Value
        'AMIImage'      = $_.ImageId
        'LaunchTime'    = $_.LaunchTime
        'State'         = $_.State.Name
        'KeyName'       = $_.KeyName
        'Platform'      = $_.Platform
        'Region'        = $Region.Name
        'PublicIP'      = $_.PublicIpAddress
        'PrivateIP'     = $_.PrivateIpAddress
        'EBS-optimized' = $_.EbsOptimized
        'SecurityGroups'= $_.SecurityGroups
        'ComputerName'  = ($_.Tags | Where-Object -FilterScript {$_.Key -eq 'CName' }).Value
        #'IamProfile'    = $_.IamInstanceProfile.Arn#.Split('/')[-1]
        'Client'        = ($_.Tags | Where-Object -FilterScript {$_.Key -eq 'Client' }).Value
        'Role'          = ($_.Tags | Where-Object -FilterScript {$_.Key -eq 'Role' }).Value
        'Environment'   = ($_.Tags | Where-Object -FilterScript {$_.Key -eq 'Environment' }).Value
      }
    }
  }
}

Remove-Item C:\temp\aws.csv
$results = $output | Where-Object {  $_.State -eq 'Running' } 
$export = $results | Select-Object InstanceName, ComputerName, Client, Role, Environment, InstanceId, InstanceType, Platform, Region, VPCName, PublicIP, PrivateIP, LaunchTime, EBS-optimized, AMIImage | Sort-Object InstanceName 
$export | Export-Csv C:\temp\aws.csv -NoTypeInformation
