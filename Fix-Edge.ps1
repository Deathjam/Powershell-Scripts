# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) 
{
  if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) 
  {
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit
  }
}
Get-Process -Name iexplore -ErrorAction SilentlyContinue | Stop-Process
Write-Host -Object 'Stopping IE processes...'
Start-Sleep -Seconds 1
Get-Process -Name MicrosoftEdge -ErrorAction SilentlyContinue | Stop-Process
Write-Host -Object 'Stopping Edge processes...'
Start-Sleep -Seconds 1
If (Test-Path -Path "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe")
{
  Write-Host -Object 'Removing Edge...'
  Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Recurse -Force
  Start-Sleep -Seconds 3
  Write-Host -Object 'Installing Edge...'
  Get-AppxPackage -AllUsers -Name Microsoft.MicrosoftEdge | ForEach-Object -Process {
    Add-AppxPackage -DisableDevelopmentMode -Register -Path "$($_.InstallLocation)\AppXManifest.xml" -Verbose
  }
}
