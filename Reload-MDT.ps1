Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
#mount deployment share as a psdrive
New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root "E:\Shares\DeploymentShare"
#Completely regenerate the boot images
Update-MDTDeploymentShare -Path "DS002:" -Verbose
#replace boot images
$Servers = "WDSServer1", "WDSServer2", "WDSServer3"
Foreach($Server in $Servers){
    wdsutil.exe /Verbose /Progress /Replace-Image /Image:"Lite Touch Windows PE (x86)" /Server:$Server /ImageType:Boot /Architecture:x86 /ReplacementImage /ImageFile:"E:\Shares\DeploymentShare\Boot\LiteTouchPE_x86.wim"
    wdsutil.exe /Verbose /Progress /Replace-Image /Image:"Lite Touch Windows PE (x64)" /Server:$Server /ImageType:Boot /Architecture:x64 /ReplacementImage /ImageFile:"E:\Shares\DeploymentShare\Boot\LiteTouchPE_x64.wim"
}
#Restart WDS service
Get-Service -Name WDSServer | Restart-Service -Verbose
