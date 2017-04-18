<#

Author: Phil Wray
Version: 1.1 18/04/2017
Usage: 
-- Edit ADMIN EMAIL ADDRESS on line 125
-- Edit paths on lines 121,126,127
-- Edit SPO url on line 146
Connect to services with modules check : Connect-Office365
Disconnect for all services: Disconnect-Office365

GitHub Repository - https://github.com/Deathjam/Powershell-Scripts

Encrypted Credentials - Adminarsenal Website. Secure Password with PowerShell: Encrypting Credentials - Part 2
http://www.adminarsenal.com/admin-arsenal-blog/secure-password-with-powershell-encrypting-credentials-part-2/

Purpose: Everything needed to connect to office 365 in one script
- Auto install Pre-Requisites modules
- Allowing for encrypted credentials or not
- The file for encrypted credentials need to be located somewhere i use onedrive, but you can network share, etc (make sure its secure)  


#>
Function Install-Check 
{
  if (!(Get-Module -ListAvailable -Name MSOnline) )#-or !(Get-Module -ListAvailable -Name SkypeOnlineConnector) -or !(Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell) ) 
  {
    $a = New-Object -ComObject wscript.shell 
    $intAnswer = $a.popup('Office 365 powershell module not detected. Install Now?', `
    0,'Pre run Check...',4) 
    If ($intAnswer -eq 6) 
    {
      New-Item -Path 'c:\temp' -ItemType Directory -Force
      Import-Module -Name BitsTransfer
      $src_msonline = 'https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi'
      $src_azure = 'https://bposast.vo.msecnd.net/MSOPMW/Current/amd64/AdministrationConfig-en.msi'
      $src_spo = 'https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/SharePointOnlineManagementShell_6323-1200_x64_en-us.msi'
      $src_spoClient = 'https://download.microsoft.com/download/B/3/D/B3DA6839-B852-41B3-A9DF-0AFA926242F2/sharepointclientcomponents_16-4002-1211_x64-en-us.msi'
      $src_skype = 'https://download.microsoft.com/download/2/0/5/2050B39B-4DA5-48E0-B768-583533B42C3B/SkypeOnlinePowershell.exe'            
      $destination = 'c:\temp\'
      $msiArgumentList = '/quiet /qr /norestart IAGREE=Yes'
      $bitsJob1 = Start-BitsTransfer -Source $src_msonline -Destination $destination
      $bitsJob2 = Start-BitsTransfer -Source $src_azure -Destination $destination
      $bitsJob3 = Start-BitsTransfer -Source $src_spo -Destination $destination
      $bitsJob4 = Start-BitsTransfer -Source $src_spoClient -Destination $destination
      $bitsJob5 = Start-BitsTransfer -Source $src_skype -Destination $destination
      $bitsJob1 | ForEach-Object -Process {
        while ($_.JobState -eq 'Transferring') 
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 10
        }
        Start-Process -FilePath $destination\msoidcli_64.msi -ArgumentList $msiArgumentList -Wait
      }
      $bitsJob2 | ForEach-Object -Process {
        while ($_.JobState -eq 'Transferring') 
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 10
        }
        Start-Process -FilePath $destination\AdministrationConfig-en.msi -ArgumentList $msiArgumentList -Wait
      }
      $bitsJob3 | ForEach-Object -Process {
        while ($_.JobState -eq 'Transferring') 
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 10
        }
        Start-Process -FilePath $destination\SharePointOnlineManagementShell_6323-1200_x64_en-us.msi -ArgumentList $msiArgumentList -Wait
      }
      $bitsJob4 | ForEach-Object -Process {
        while ($_.JobState -eq 'Transferring') 
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 10
        }
        Start-Process -FilePath $destination\sharepointclientcomponents_16-4002-1211_x64-en-us.msi -ArgumentList $msiArgumentList -Wait
      }
      $bitsJob5 | ForEach-Object -Process {
        while ($_.JobState -eq 'Transferring') 
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 10
        }
        Start-Process -FilePath $destination\SkypeOnlinePowershell.exe -ArgumentList '/quiet /NoRestart' -Wait
      } 
    }  
  }
}

Function Disconnect-Office365
{
  Get-PSSession |
  Where-Object -FilterScript {
    $_.ComputerName -like '*.outlook.com' -or $_.ComputerName -like '*.lync.com' -or $_.ComputerName -like '*.office365.com'
  } |
  Remove-PSSession |
  Disconnect-SPOService
}

Function Connect-Office365
{
  try
  {
    Install-Check
    Get-OrganizationConfig -ErrorAction Stop > $null
  }
  catch 
  {
    Import-Module -Name 'Microsoft.PowerShell.Security'
    if((Test-Path -Path "$ENV:UserProfile\OneDrive - COMPANY\PowerShell\"))
    {
      #Taken From Adminarsenal Website. Secure Password with PowerShell: Encrypting Credentials - Part 2
      #http://www.adminarsenal.com/admin-arsenal-blog/secure-password-with-powershell-encrypting-credentials-part-2/
      $User = 'ADMIN EMAIL ADDRESS'
      $PasswordFile = "$ENV:UserProfile\OneDrive - COMPANY\PowerShell\Auth\Password.txt"
      $KeyFile = "$ENV:UserProfile\OneDrive - COMPANY\PowerShell\Auth\AES.key"
      $key = Get-Content $KeyFile
      $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
    }
    else 
    {
      $User = Read-Host -Prompt 'Please enter 365 admin login'
      $pass = Read-Host -Prompt 'Please enter 365 admin password'
      $securepassword = ConvertTo-SecureString -String $pass -AsPlainText -Force 
      $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($User, $securepassword)
    }
    #Connect to 365
    Import-Module -Name MsOnline
    Connect-MsolService -Credential $credential
    #Connect to Exchange
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $credential -Authentication 'Basic' -AllowRedirection
    Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber
    #Connect to Sharepoint
    Import-Module -Name Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
    Connect-SPOService -Url https://TENENT-admin.sharepoint.com -Credential $credential
    #Connect to Skype
    Import-Module -Name SkypeOnlineConnector
    $sfboSession = New-CsOnlineSession -Credential $credential
    Import-PSSession -Session $sfboSession
    #Connect to compliance center
    $ccSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection
    Import-PSSession -Session $ccSession -Prefix cc
  }
}
