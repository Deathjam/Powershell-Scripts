# List the Windows disks
function Get-Ebsmaps
{

  function Get-EC2InstanceMetadata
  {
    param([string]$Path)
    (Invoke-WebRequest -Uri "http://169.254.169.254/latest/$Path").Content 
  }

  function Convert-SCSITargetIdToDeviceName
  {
    param([int]$SCSITargetId)
    If ($SCSITargetId -eq 0) 
    {
      return '/dev/sda1'
    }
    $deviceName = 'xvd'
    If ($SCSITargetId -gt 25) 
    {
      $deviceName += [char](0x60 + [int]($SCSITargetId / 26))
    }
    $deviceName += [char](0x61 + $SCSITargetId % 26)
    return $deviceName
  }

  Try 
  {
    $InstanceId = Get-EC2InstanceMetadata 'meta-data/instance-id'
    $AZ = Get-EC2InstanceMetadata 'meta-data/placement/availability-zone'
    $Region = $AZ.Remove($AZ.Length - 1)
    $BlockDeviceMappings = (Get-EC2Instance -Region $Region -Instance $InstanceId).Instances.BlockDeviceMappings
    $VirtualDeviceMap = @{}
    (Get-EC2InstanceMetadata 'meta-data/block-device-mapping').Split("`n") | ForEach-Object -Process {
      $VirtualDevice = $_
      $BlockDeviceName = Get-EC2InstanceMetadata "meta-data/block-device-mapping/$VirtualDevice"
      $VirtualDeviceMap[$BlockDeviceName] = $VirtualDevice
      $VirtualDeviceMap[$VirtualDevice] = $BlockDeviceName
    }
  }
  Catch 
  {
    Write-Host -Object 'Could not access the AWS API, therefore, VolumeId is not available. 
    Verify that you provided your access keys.' -ForegroundColor Yellow
  }

  Get-WmiObject -Class Win32_DiskDrive |
  ForEach-Object -Process {
    $DiskDrive = $_
    $Volumes = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($DiskDrive.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition" |
    ForEach-Object -Process {
      $DiskPartition = $_
      Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($DiskPartition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
    $PartitionStyle = Get-Disk | Where-Object {$_.Number -eq  $($DiskDrive.Index)} | Select-Object -Property PartitionStyle
    $partitionSize = Get-Disk | Where-Object {$_.Number -eq  $($DiskDrive.Index)} | Select-Object -Property AllocatedSize
    } 

    If ($DiskDrive.PNPDeviceID -like '*PROD_PVDISK*') 
    {
      $BlockDeviceName = Convert-SCSITargetIdToDeviceName($DiskDrive.SCSITargetId)
      $BlockDevice = $BlockDeviceMappings |
      Where-Object -FilterScript {
        $_.DeviceName -eq $BlockDeviceName 
      }
      $VirtualDevice = If ($VirtualDeviceMap.ContainsKey($BlockDeviceName)) 
      {
        $VirtualDeviceMap[$BlockDeviceName] 
      }
      Else 
      {
        $null 
      }
    }
    ElseIf ($DiskDrive.PNPDeviceID -like '*PROD_AMAZON_EC2_NVME*') 
    {
      $BlockDeviceName = Get-EC2InstanceMetadata "meta-data/block-device-mapping/ephemeral$($DiskDrive.SCSIPort - 2)"
      $BlockDevice = $null
      $VirtualDevice = If ($VirtualDeviceMap.ContainsKey($BlockDeviceName)) 
      {
        $VirtualDeviceMap[$BlockDeviceName] 
      }
      Else 
      {
        $null 
      }
    }
    Else 
    {
      $BlockDeviceName = $null
      $BlockDevice = $null
      $VirtualDevice = $null
    }

    New-Object -TypeName PSObject -Property @{
      ComputerName   = $env:COMPUTERNAME  
      Disk           = $DiskDrive.Index
      Partitions     = $DiskDrive.Partitions
      DriveLetter    = If ($Volumes -eq $null) 
      {
        'N/A' 
      }
      Else 
      {
        $Volumes.DeviceID 
      }
      EbsVolumeId    = If ($BlockDevice -eq $null) 
      {
        'N/A' 
      }
      Else 
      {
        $BlockDevice.Ebs.VolumeId 
      }
      Device         = If ($BlockDeviceName -eq $null) 
      {
        'N/A' 
      }
      Else 
      {
        $BlockDeviceName 
      }
      VirtualDevice  = If ($VirtualDevice -eq $null) 
      {
        'N/A' 
      }
      Else 
      {
        $VirtualDevice 
      }
      VolumeName     = If ($Volumes -eq $null) 
      {
        'N/A' 
      }
      Else 
      {
        $Volumes.VolumeName 
      }
      PartitionStyle = if($PartitionStyle.PartitionStyle -contains "GPT")
      {
        'GPT'
      }
      else
      {
        'MBR'
      }
      'Partition Size GB' = [math]::Round($partitionSize.AllocatedSize/1GB)      
    }
  } |
  Sort-Object -Property Disk |
  Select-Object -Property Computername, Disk, Partitions, DriveLetter, EbsVolumeId, Device, VirtualDevice, VolumeName, PartitionStyle, 'Partition Size GB' |
  Format-Table -AutoSize
}
Get-Ebsmaps 
