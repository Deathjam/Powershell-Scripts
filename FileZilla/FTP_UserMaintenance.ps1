#Script to automatically disable old FTP accounts
#Also: 
#- archives very old FTP accounts (moves the data and deletes the account)
#- warns users via e-mail that ftp accounts they have created/updated are due to expire
#- warns users via e-mail that ftp accounts they have created/updated have been archived/deleted
#
#This script should be executed on the FileZilla server
#
#Requirements:
#- If running as a Scheduled Task (advised), the account executing this script requires "Log on as a Batch Job" permissions on the FileZilla server
#
#- Editing the FileZilla XML:
#  - The user running this script needs NTFS Modify permissions on the "%PROGRAM FILES (x86)%\FileZilla Server\FileZilla Server.xml"
#- Reloading the FileZilla Config
#  - Set-ExecutionPolicy to be set to RemoteSigned (or lower) on the computer running this script and on the FileZilla server (unless you sign the scripts yourself)
#  - The account executing this script requires local admin permissions on the FileZilla server (to execute the /reload-config command)
#- Archiving
#  - The account executing this script requires Modify NTFS permissions on $ftpDataShare to delete old directories
#  - The account executing this script requires Change Share permissions on $ftpDataShare to delete old directories
#  - The account executing this script requires Write NTFS permissions on $ftpDataArchivePath to move old directories
#  - The account executing this script requires Change Share permissions on $ftpDataArchivePath to move old directories
#- Sending e-mail
#  - The user running this script needs to be able to send mail via $smtpServer from the command line (either by relaying or you can add authentication)
#  - The emailUser function assumes that the user's mailAlias is the same as their username, and that it can construct valid e-mail addresses from username@upn
#
#If you like the script, feel free to pop a beer in the post c/o Kev Maitland - I work at the head office of www.sustain.co.uk :)


$filezillaServer = "yourFileZillaServer"
$ftpDataShare = "yourFTPDataShare"
$ftpDataArchivePath = "yourFTPArchiveShare" 
$xmlFilePath = "\\$filezillaServer\FileZillaServer$\FileZilla Server.xml"
$reloadFZConfigCMD = '"C:\Program Files (x86)\FileZilla Server\FileZilla Server.exe" "/reload-config"'
$smtpServer = "yourMailServer
$upn = "@yourdomain.local"
$mailFrom = "ftpserver@yourdomain.local"
$replyTo = "nooneislistening@yourdomain.local"

$daysBeforeDisabling = 30
$daysBeforeArchiving = 90
$warningDaysOffset = 7
[datetime]$date = Get-Date -Format yyyyMMMMdd #Gets Date without Time data

function emailUser([string]$to, [string]$subject, [string]$body){
    $msg = New-Object Net.Mail.MailMessage
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $mailFrom
    $msg.ReplyTo = $replyTo
    $msg.To.Add("$to$upn")
    $msg.subject = $subject
    $msg.body = $body
    $smtp.Send($msg)
    }

#------------------------------------------
#---Import the FileZilla XML file so that we can examine the accounts
#------------------------------------------
$xml = [xml](Get-Content $xmlFilePath)
 
#------------------------------------------
#---Go through every user and do stuff based on when the account was last updated
#------------------------------------------
foreach ($user in $xml.FileZillaServer.Users.User){ 
    $comments = ($user.SelectSingleNode("Option[@Name='Comments']").InnerText).Split()
    $lastUpdated = get-date $comments[10]
        if ($user.Name -eq "TemplateFTPUser"){Continue}
        Write-Host -ForegroundColor Yellow $user.Name
        Write-Host -ForegroundColor DarkYellow "Last updated "$($date - $lastUpdated).Days" days ago ("$lastUpdated")"
    if ($($date - $lastUpdated).Days -ge $daysBeforeArchiving) {
        Write-Host -ForegroundColor DarkYellow "Archiving..."
        $lastUpdatedBy = $comments[8]
        $userGroup = $user.SelectSingleNode("Option[@Name='Group']").InnerText
        if ($userGroup -eq ""){$userGroup = "None"}
        if (!(Test-Path "$ftpDataArchivePath\$userGroup")){New-Item -ItemType Directory -Path "\\$ftpDataArchivePath\$userGroup"}
        Move-Item "\\$filezillaServer\$ftpDataShare\$userGroup\$($user.Name)" "$ftpDataArchivePath\$userGroup\$($user.Name)" -Force #This assumes that the executing user has write permissions to $archivePath

        $subject = "FTP Account `"$($user.Name)`" has been archived"
        $body = `
"Hello,`n `
The account called $($user.Name) that you created/updated on $(Get-Date $lastUpdated -Format "dd MMMM yy") has been archived. The actual FTP account has been deleted and any files have been moved to the archive area:`n '
    $ftpDataArchivePath\$userGroup\$($user.Name) `n 
If your client needs to transfer you files via secure FTP in the future, you will need to create them a new FTP account using the instructions at:`n `
    http://intranet.sustain.co.uk/ict/SitePages/FTP%20Help.aspx `n `
Love,`n `
The Helpful FTP Robot"
        emailUser -to $lastUpdatedBy -subject $subject -body $body
        $xml.FileZillaServer.Users.RemoveChild($user)
        }
    elseif ($($date - $lastUpdated).Days -ge $daysBeforeDisabling){
        Write-Host -ForegroundColor DarkYellow "Disabling..."
        $user.SelectSingleNode("Option[@Name='Enabled']").InnerText = 0 #This disables the account in FileZilla
        }
    elseif ($($date - $lastUpdated).Days -ge $daysBeforeDisabling-1){
        Write-Host -ForegroundColor DarkYellow "2nd warning..."
        $lastUpdatedBy = $comments[8]
        $subject = "FTP account `"$($user.Name)`" will expire tomorrow"
        $body = `
"Hello,`n `
The account called $($user.Name) that you created/updated on $(Get-Date $lastUpdated -Format "dd MMMM yy") is due to expire on $(Get-Date $date.AddDays(1) -Format "dd MMMM yy"). If you want to pre-empt this, you can reset the password by following the instructions available at: `n `
    http://intranet.sustain.co.uk/ict/SitePages/FTP%20Help.aspx `n `
If you're no longer using the account, you can just ignore this and it will automatically be deactivated tomorrow, and archived on $(Get-Date $date.AddDays($daysBeforeArchiving+1) -Format "dd MMMM yy"), `n `
Love,`n `
The Helpful FTP Robot"
        emailUser -to $lastUpdatedBy -subject $subject -body $body
        }
    elseif ($($date - $lastUpdated).Days -ge $daysBeforeDisabling-$warningDaysOffset){
        Write-Host -ForegroundColor DarkYellow "1st warning..."
        $lastUpdatedBy = $comments[8]
        $subject = "FTP account `"$($user.Name)`" will expire in $warningDaysOffset days"
        $body = `
"Hello,`n `
The account called $($user.Name) that you created/updated on $(Get-Date $lastUpdated -Format "dd MMMM yy") is due to expire on $(Get-Date $date.AddDays($warningDaysOffset) -Format "dd MMMM yy"). If you want to pre-empt this, you can reset the password by following the instructions available at: `n `
    http://intranet.sustain.co.uk/ict/SitePages/FTP%20Help.aspx `n `
If you're no longer using the account, you can just ignore this and it will automatically be deactivated on $(Get-Date $date.AddDays($warningDaysOffset) -Format "dd MMMM yy"), and archived on $(Get-Date $date.AddDays($daysBeforeArchiving+$warningDaysOffset) -Format "dd MMMM yy"), `n `
Love,`n `
The Helpful FTP Robot"
        emailUser -to $lastUpdatedBy -subject $subject -body $body
        }
    else {Write-Host -foregroundcolor Darkyellow "Doing nothing..."}
   }

#------------------------------------------
#---Reload the FileZilla config to initialise the changes
#------------------------------------------
$xml.Save($xmlFilePath)
iex "& $reloadFZConfigCMD"
