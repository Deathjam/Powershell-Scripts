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
  if (!(Get-Module -ListAvailable -Name MSOnline) -or !(Get-Module -ListAvailable -Name SkypeOnlineConnector) -or !(Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell) ) 
  {
    $a = New-Object -ComObject wscript.shell 
    $intAnswer = $a.popup('Office 365 powershell module not detected. Install Now?', `
    0,'Pre run Check...',4) 
    If ($intAnswer -eq 6) 
    {
      #Create temp folder for 365 install files
      New-Item -Path "$env:temp\365install" -ItemType Directory -Force
      
      #Import BITS module
      Import-Module -Name BitsTransfer
      
      #Online Services Sign-In Assistant (64 Bit)
      $src_msonline = 'https://download.microsoft.com/download/7/1/E/71EF1D05-A42C-4A1F-8162-96494B5E615C/msoidcli_64bit.msi'
      #Windows Azure AD Module (64 Bit) 
      # use Install-Module -Name AzureAD 
      #$src_azure = 'https://bposast.vo.msecnd.net/MSOPMW/Current/amd64/AdministrationConfig-en.msi'
      #SharePoint Online Management Shell
      $src_spo = 'https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/sharepointonlinemanagementshell_6906-1200_x64_en-us.msi'
      #SharePoint Online Client Components SDK
      $src_spoClient = 'https://download.microsoft.com/download/B/3/D/B3DA6839-B852-41B3-A9DF-0AFA926242F2/sharepointclientcomponents_16-6906-1200_x64-en-us.msi'
      #Skype for Business Online, Windows PowerShell Module
      $src_skype = 'https://download.microsoft.com/download/2/0/5/2050B39B-4DA5-48E0-B768-583533B42C3B/SkypeOnlinePowershell.exe' 
                 
      $destination = "$env:temp\365install"
      $msiArgumentList = '/quiet /qr /norestart IAGREE=Yes'
      $bitsJob1 = Start-BitsTransfer -Source $src_msonline -Destination $destination -Asynchronous
      #$bitsJob2 = Start-BitsTransfer -Source $src_azure -Destination $destination -Asynchronous
      $bitsJob3 = Start-BitsTransfer -Source $src_spo -Destination $destination -Asynchronous
      $bitsJob4 = Start-BitsTransfer -Source $src_spoClient -Destination $destination -Asynchronous
      $bitsJob5 = Start-BitsTransfer -Source $src_skype -Destination $destination -Asynchronous
      #region Online Services Sign-In Assistant
      Write-Host "Downloading Online Services Sign-In Assistant"
      $bitsJob1 | ForEach-Object -Process {
        while (($_.JobState.ToString() -eq 'Transferring') -or ($_.JobState.ToString() -eq 'Connecting'))
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 4
        }
        if ($_.InternalErrorCode -ne 0) {
            ('Error downloading Sign-In Assistant' -f $_.InternalErrorCode) | Out-File "$destination\SignIn_Assistant_DownloadError.log"}
        else {
            Complete-BitsTransfer -BitsJob $_
            Write-Host -foregroundcolor green "The Online Services Sign-In Assistant Download Completed Successfully"
            Start-Process -FilePath $destination\msoidcli_64.msi -ArgumentList $msiArgumentList -Wait 
            Write-Host -foregroundcolor green "The Online Services Sign-In Assistant Install Completed Successfully"
        }      
      }
      #endregion Online Services Sign-In Assistant
      #region Windows Azure AD Module
      Write-Host "Installing  Azure AD Module"
      Install-Module -Name AzureAD -Force
      <#
      Write-Host "Downloading Windows Azure AD Module"
      $bitsJob2 | ForEach-Object -Process {
        while (($_.JobState.ToString() -eq 'Transferring') -or ($_.JobState.ToString() -eq 'Connecting'))
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 4
        }
        if ($_.InternalErrorCode -ne 0) {
            ('Error downloading Windows Azure AD Module' -f $_.InternalErrorCode) | Out-File "$destination\Windows Azure AD Module.log"}
        else {
            Complete-BitsTransfer -BitsJob $_
            Write-Host -foregroundcolor green "The Windows Azure AD Module Download Completed Successfully"
            Start-Process -FilePath $destination\administrationConfig-en.msi -ArgumentList $msiArgumentList -Wait 
            Write-Host -foregroundcolor green "The Windows Azure AD Module Install Completed Successfully"
        }    
      }
      #>
      #endregion Windows Azure AD Module
      #region SharePoint Online Management Shell
      Write-Host "Downloading SharePoint Online Management Shell"
      $bitsJob3 | ForEach-Object -Process {
        while (($_.JobState.ToString() -eq 'Transferring') -or ($_.JobState.ToString() -eq 'Connecting'))
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 4
        }
        if ($_.InternalErrorCode -ne 0) {
            ('Error downloading SharePoint Online Management Shell' -f $_.InternalErrorCode) | Out-File "$destination\SharePoint Online Management Shell.log"}
        else {
            Complete-BitsTransfer -BitsJob $_
            Write-Host -foregroundcolor green "The SharePoint Online Management Shell Download Completed Successfully"
            Start-Process -FilePath $destination\sharepointonlinemanagementshell_6906-1200_x64_en-us.msi -ArgumentList $msiArgumentList -Wait 
            Write-Host -foregroundcolor green "The SharePoint Online Management Shell Install Completed Successfully"
        }    
      }
      #endregion SharePoint Online Management Shell
      #region SharePoint Online Client Components SDK
      Write-Host "Downloading SharePoint Online Client Components SDK"
      $bitsJob4 | ForEach-Object -Process {
        while (($_.JobState.ToString() -eq 'Transferring') -or ($_.JobState.ToString() -eq 'Connecting'))
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 4
        }
        if ($_.InternalErrorCode -ne 0) {
            ('Error downloading SharePoint Online Client Components SDK' -f $_.InternalErrorCode) | Out-File "$destination\SharePoint Online Client Components SDK.log"}
        else {
            Complete-BitsTransfer -BitsJob $_
            Write-Host -foregroundcolor green "The SharePoint Online Client Components SDK Download Completed Successfully"
            Start-Process -FilePath $destination\sharepointclientcomponents_16-6906-1200_x64-en-us.msi -ArgumentList $msiArgumentList -Wait 
            Write-Host -foregroundcolor green "The SharePoint Online Client Components SDK Install Completed Successfully"
        }    
      }
      #endregion SharePoint Online Client Components SDK
      #region Skype for Business Online
      Write-Host "Downloading Skype for Business Online, Windows PowerShell Module"
      $bitsJob5 | ForEach-Object -Process {
        while (($_.JobState.ToString() -eq 'Transferring') -or ($_.JobState.ToString() -eq 'Connecting'))
        {
          $pctComplete = [int](($_.BytesTransferred * 100)/$_.BytesTotal)
          Clear-Host
          Write-Progress -Activity 'File Transfer in Progress' -Status "% Complete: $pctComplete" -PercentComplete $pctComplete
          Start-Sleep -Seconds 4
        }
        if ($_.InternalErrorCode -ne 0) {
            ('Error downloading Skype for Business Online' -f $_.InternalErrorCode) | Out-File "$destination\Skype for Business Online.log"}
        else {
            Complete-BitsTransfer -BitsJob $_
            Write-Host -foregroundcolor green "The Skype for Business Online Download Completed Successfully"
            Start-Process -FilePath $destination\SkypeOnlinePowershell.exe -ArgumentList '/quiet /NoRestart' -Wait 
            Write-Host -foregroundcolor green "The Skype for Business Online Install Completed Successfully"
        }    
      } 
      #endregion Skype for Business Online
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
