Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
#new-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "E:\Shares\DeploymentShare" -Description "MDT Deployment Share" -NetworkPath "\\SERVER\DeploymentShare$" -Verbose | add-MDTPersistentDrive -Verbose
New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root "E:\Shares\DeploymentShare"
Update-MDTDeploymentShare -Path "DS002:" -Verbose

$Servers = "WDSServer1", "WDSServer2", "WDSServer3"
Foreach($Server in $Servers){
    wdsutil.exe /Verbose /Progress /Replace-Image /Image:"Lite Touch Windows PE (x86)" /Server:$Server /ImageType:Boot /Architecture:x86 /ReplacementImage /ImageFile:"E:\Shares\DeploymentShare\Boot\LiteTouchPE_x86.wim"
    wdsutil.exe /Verbose /Progress /Replace-Image /Image:"Lite Touch Windows PE (x64)" /Server:$Server /ImageType:Boot /Architecture:x64 /ReplacementImage /ImageFile:"E:\Shares\DeploymentShare\Boot\LiteTouchPE_x64.wim"
}

Get-Service -Name WDSServer | Restart-Service -Verbose
