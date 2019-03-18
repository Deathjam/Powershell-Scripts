#Script to allow a user to select an account from FileZilla and reset the password.
#Also reactivates an account if it has been disabled, and uses the Comments XML element under the User node for auditing
#
#Can be executed on a PC/server other than the FileZilla server (e.g. Remote Desktop server)
#
#Requirements:
#- Editing the FileZilla XML:
#  - The "%PROGRAM FILES (x86)%\FileZilla Server" directory on the FileZilla server to be shared as "FileZillaServer$" and the user running this script needs Change permissions on the share
#  - The user running this script needs NTFS Modify permissions on the "\\$filezillaServer\FileZillaServer$\FileZilla Server.xml"
#- Reloading the FileZilla Config
#  - Set-ExecutionPolicy to be set to RemoteSigned (or lower) on the computer running this script and on the FileZilla server (unless you sign the scripts yourself)
#  - A script that contains the commands required to reload the FileZilla config (otherwise the FileZilla services need to be restarted)
#  - A PSSessionConfiguration on the FileZilla server with a -RunAsCredential with local admin rights and Invoke permission (required for the /reload-config command to work)
#      - This recommends a dedicated local administrator account on the FileZilla server that can be locked down further as required
#
#Does not require:
#- Local Administrator permissions for the user running this script on the computer running this script
#- Local Administrator permissions for the user running this script on the FileZilla server
#
#If you like the script, feel free to pop a beer in the post c/o Kev Maitland - I work at the head office of www.sustain.co.uk :)


$filezillaServer = "yourFileZillaServer"
$ftpDataShare = "yourFTPDataShare"
$xmlFilePath = "\\$filezillaServer\FileZillaServer$\FileZilla Server.xml"
$reloadFZConfigCmdPath = "\\$filezillaServer\FileZillaServer$\ReloadConfig.ps1"
$psSessionConfigurationNameOnFileZillaServer = "FileZilla"
$date = Get-Date

$formTitle = "Secure FTP Password Reset"
 
function formCaptureText([string]$formTitle, [string]$formText){
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = $formTitle
    $objForm.Size = New-Object System.Drawing.Size(300,200) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$script:capturedText = $objTextBox.Text;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$objForm.Close();$script:capturedText = ""}})


    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({$script:capturedText=$objTextBox.Text;$objForm.Close()})
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objForm.Close();$script:capturedText = ""})
    $objForm.Controls.Add($CancelButton)

    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,40) 
    $objLabel.Text = $formText
    $objForm.Controls.Add($objLabel) 

    $objTextBox = New-Object System.Windows.Forms.TextBox 
    $objTextBox.Location = New-Object System.Drawing.Size(10,60) 
    $objTextBox.Size = New-Object System.Drawing.Size(260,20) 
    $objForm.Controls.Add($objTextBox) 

    $objForm.Topmost = $True

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()

    $capturedText
    }
function formCaptureSelection([string]$formTitle, [string]$formText, [string[]]$choices){
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = $formTitle
    $objForm.Size = New-Object System.Drawing.Size(300,200) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$script:capturedSelection = $objTextBox.Text;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$objForm.Close();$script:capturedSelection = ""}})


    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({$script:capturedSelection=$objListBox.SelectedItem;$objForm.Close()})
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objForm.Close();$script:capturedSelection = ""})
    $objForm.Controls.Add($CancelButton)

    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,20) 
    $objLabel.Text = $formText
    $objForm.Controls.Add($objLabel) 

    $objListBox = New-Object System.Windows.Forms.ListBox 
    $objListBox.Location = New-Object System.Drawing.Size(10,40) 
    $objListBox.Size = New-Object System.Drawing.Size(260,20) 
    $objListBox.Height = 80
    foreach ($choice in $choices){
        [void] $objListBox.Items.Add($choice)
        }
    $objForm.Controls.Add($objListBox) 

    $objForm.Topmost = $True
    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()

    $capturedSelection
    }
function hashMeAPassword([string]$clearText){
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $passHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($clearText))).ToLower() -replace "-",""
    $passHash
    }

#Import the FileZilla XML file so that we can reactivate accounts
$xml = [xml](Get-Content $xmlFilePath)
 
#Get a list of active accounts for the user to pick from
$listOfUsernames = @()
foreach ($ftpUsername in $xml.FileZillaServer.Users.User){$listOfUsernames += $ftpUsername.Name}
[Array]::Sort([array]$listOfUsernames)

#Get the user to select the account to reset from $listOfUsernames
$ftpUsername = formCaptureSelection $formTitle "Please select the user to reset their password:" $listOfUsernames
if ($ftpUsername -eq ""){write-host "Empty username. Exiting now";exit} #If either values are empty, quit. 
$FZUserForResetting = $xml.SelectSingleNode("/FileZillaServer/Users/User[@Name='$ftpUsername']")
$FZUserForResettingPassword = $FZUserForResetting.SelectSingleNode("Option[@Name='Pass']")
$FZUserForResettingOldComments = $FZUserForResetting.SelectSingleNode("Option[@Name='Comments']")

#Get a new password
$ftpPassword = formCaptureText $formTitle "Please enter a new, strong password below:"
$passHash = hashMeAPassword $ftpPassword
while (($ftpPassword.Length -lt 8) -or ($ftpPassword -eq $ftpUsername) -or ($ftpPassword -match "123") -or ($passHash -eq $FZUserForResettingPassword.InnerText)){
    if ($ftpPassword -eq ""){write-host "Empty password. Exiting now";exit} #If value is empty, quit. 
    $ftpPassword = formCaptureText $formTitle "Don't be an plonker, $env:username. Enter a proper /strong/ *new* password below. You can generate them at http://strongpasswordgenerator.com/:"
    $passHash = hashMeAPassword $ftpPassword
    }

#Then reactivate the account in the FileZilla XML file and update the Comments element with the LastUpdated and UpdatedBy data
Write-Host -ForegroundColor Yellow "Resetting password for $ftpUsername"
$FZUserForResettingPassword.InnerText = $passHash #This bit overwrites the old password with a new one
$FZUserForResetting.SelectSingleNode("Option[@Name='Enabled']").InnerText = 1 #This re-enables them in case the account has expired
$FZUserForResettingNewComments = ($FZUserForResettingOldComments.InnerText).split(" ")
$FZUserForResettingNewComments[8] = $env:username #Set the "UpdatedBy" username to the current user
$FZUserForResettingNewComments[10] = Get-Date $date -Format yyyy/MM/dd #Set the "LastUpdated" date to the new date
$FZUserForResettingNewComments[11] = Get-Date $date -Format hh:mm:ss #Set the "LastUpdated" time to the new time
$FZUserForResettingNewCommentsAsASingleString = ""
foreach ($word in $FZUserForResettingNewComments){$FZUserForResettingNewCommentsAsASingleString += "$word "} #Rewrite the updated comments into a single long string again
$FZUserForResetting.SelectSingleNode("Option[@Name='Comments']").InnerText = $FZUserForResettingNewCommentsAsASingleString #Assign the final version of the updated comments
$xml.Save($xmlFilePath) #Save the XML data

 
#------------------------------------------
#---Reload the FileZilla config to initialise the new user
#------------------------------------------
Write-Host -ForegroundColor DarkYellow "Activating $ftpUsername ..."
Invoke-Command -ComputerName $filezillaServer -FilePath $reloadFZConfigCmdPath -ConfigurationName $psSessionConfigurationNameOnFileZillaServer

Write-Host -ForegroundColor Yellow "User password reset! Press enter to exit this window"
$null = Read-Host
