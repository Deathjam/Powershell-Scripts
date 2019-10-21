#requires -Version 3.0
function Remove-365Users {
    param( 
        [Parameter(Mandatory = $True,
        HelpMessage = 'Please provide the path of the CSV file containing the users', Position = 0)]
        [String]$CSVPath
        )

    #Set Credentials
    $credential = (Get-Credential -Message "Enter Office 365 Admin details")
    if($credential) {
        #Connect to 365
        Import-Module -Name MsOnline
        Connect-MsolService -Credential $credential
        #Connect to Exchange
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $credential -Authentication 'Basic' -AllowRedirection
        Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber
        #Import-Module -Name ActiveDirectory

        #list of users
        #$users = @(
        #  ''
        #)
        $leavers = (Get-Content -Path $CSVPath | ConvertFrom-Csv -Header User).user

        foreach ($leaver in $leavers) {
          Function Get-Passwd 
          {
            $path = 'c:\temp\fourlist.txt'
            if (!( Test-Path $path))
            {
              New-Item -ItemType Directory -Path C:\temp\
              Invoke-WebRequest -Uri 'https://s3-eu-west-1.amazonaws.com/public-fourlist/fourlist.txt' -OutFile $path 
              Start-Sleep -Seconds 2
            }    
            $Word = Get-Content -Path $path |
            Sort-Object -Property {
                Get-Random
            } |
            Select-Object -First 1
            $Word2 = Get-Content -Path $path |
            Sort-Object -Property {
                Get-Random
            } |
            Select-Object -First 1
            $num = Get-Random  -Maximum 999

            return $password = '$'+$Word + $Word2 + $num
          }
          $passwd = Get-Passwd

          Write-Host -Object 'Resetting Password...'
          Set-MsolUserPassword -UserPrincipalName $leaver -NewPassword $passwd -ForceChangePassword $false
          Write-Host -Object "Removing $leaver from Distribution Groups..."
          $mailbox = get-mailbox $leaver
          $dgs = Get-DistributionGroup

          foreach($dg in $dgs)
          {
              $DGMs = Get-DistributionGroupMember -identity $dg.Identity
              foreach ($dgm in $DGMs)
              {
                  if ($dgm.name -eq $mailbox.name)
                  {
                      Write-Host 'User Found In Group' $dg.identity
                      Remove-DistributionGroupMember $dg.Name -Member $leaver -Confirm:$false
                  }
              }
          }  
          Write-Host -Object 'Clean up...'
          Write-Host -Object '================='

          Set-Mailbox -Identity $leaver -HiddenFromAddressListsEnabled $true
          Write-Host -Object "Converting $leaver to a Shared Mailbox..."
          Set-Mailbox $leaver -Type shared

          Write-Host -Object 'Removing License...'
          $license = Get-MsolUser -UserPrincipalName $leaver | ForEach-Object -Process {
              $_.Licenses | Select-Object -Property AccountSKuid -ExpandProperty AccountSKuid
          }
          Set-MsolUserLicense -UserPrincipalName $leaver -RemoveLicenses $license
          Set-MsolUser -UserPrincipalName $leaver -BlockCredential $true

          Write-Host -Object 'Office 365 Leaver Process Completed'
          Write-Host -Object 'Checking settings are correct'

          Write-Host -Object "$leaver password is now $passwd"
          Get-Mailbox $leaver | Format-List -Property DeliverToMailboxAndForward, ForwardingAddress, ForwardingSmtpAddress, RecipientTypeDetails  
        }
    }
    else {
        Write-host -ForegroundColor Red "Please enter a 365 Admin Credential"
    }
}
