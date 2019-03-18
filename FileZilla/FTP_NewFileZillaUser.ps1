#Script to create a new user in FileZilla
#Uses the Comments XML element under the User node for auditing
#
#Can be executed on a PC/server other than the FileZilla server (e.g. Remote Desktop server)
#
#Requirements:
#- A template FTP user account to be created on the FileZilla server (this makes it easy to set default option specific to your environment, e.g. Enforce SSL)
#- Additional Groups to be created manually in FileZilla Server, and to have the corresponding filesystem folders created manually too.
#- The user running this script needs Modify Share permissions on the $ftpDataShare share to create the directory for the new account
#- The user running this script needs NTFS Write permissions on the $ftpDataShare\$ftpGroup directories to create the directory for the new account
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
$localPathToFTPDataShareOnFileZillaServer = "D:" #Used to map user's Home Folder locally, rather than via UNC
$xmlFilePath = "\\$filezillaServer\FileZillaServer$\FileZilla Server.xml"
$psSessionConfigurationNameOnFileZillaServer = "FileZilla"
$reloadFZConfigCmdPath = "\\$filezillaServer\FileZillaServer$\ReloadConfig.ps1"
$formTitle = "Secure FTP User Creation"
$disallowedCharacters = @("\<", "\>", "\:", '\"', "\/", "\\", "\|", "\?", '\*', "\ ", "\'", "\,", "\^") -join '|' #Use RegEx escape character (\) here, not PowerShell (`)
$date = Get-Date

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

#Open the XML document so that we can check for duplicate usernames
$xml = [xml](Get-Content $xmlFilePath)

#Generate a form to capture the new account name and perform some validation. Usernames need to converted to lowercase as XML is case sensitive (and everything else is not)
$ftpUsernameValid = $false
$ftpUsername = (formCaptureText $formTitle "Please enter the new username below (don't use spaces or symbols in the username):").ToLower()
while ($ftpUsernameValid -eq $false){
    if ($ftpUsername -eq ""){write-host "Empty username. Exiting now";exit} #If username is empty, quit.
    $ftpUsernameValid = $true
    if ($xml.SelectSingleNode("/FileZillaServer/Users/User[@Name='$ftpUsername']") -ne $null){ #Don't let the user choose an pre-existing username
        $ftpUsernameValid = $false
        $ftpUsername = (formCaptureText $formTitle "Username already in use - please choose another (don't use spaces or symbols):").ToLower()
        }
    if ($ftpUsername -match $disallowedCharacters){ #Make sure that the user hasn't chosen any spaces or symmbols in the account name
        $ftpUsernameValid = $false
        $ftpUsername = (formCaptureText $formTitle "Oi $env:username! I said /don't/ use spaces or symbols! Try again:").ToLower()
        }
    }

#Generate a form to capture the new password and perform some rudimentary validiation
$ftpPassword = formCaptureText $formTitle "Please enter the new (strong) password below:"
while (($ftpPassword.Length -lt 8) -or ($ftpPassword -eq $ftpUsername) -or ($ftpPassword -match "123")){
    if ($ftpPassword -eq ""){write-host "Empty password. Exiting now";exit} #If password is empty, quit. 
    $ftpPassword = formCaptureText $formTitle "Don't be an idiot, $env:username. Enter a proper /strong/ password below. You can generate them at http://strongpasswordgenerator.com/:"
    }

#Generate a form to capture the new account's group (doesn't require additional validation as they are picking from a list)
$ftpGroupsArray = @()
foreach ($ftpGroup in $xml.FileZillaServer.Groups.Group){$ftpGroupsArray += $ftpGroup.Name} #Pull the list of Groups from the FileZilla XML
[Array]::Sort([array]$ftpGroupsArray) #Sort the list of Groups
$ftpGroupsArray += "None" #Add a final "None" option

$ftpGroup = formCaptureSelection "Secure FTP User Creation" "Please select the appropriate group for the new user:" $ftpGroupsArray
if ($ftpGroup -eq ""){write-host "Empty group. Exiting now";exit} #If either values are empty, quit. 



cls
Write-Host -ForegroundColor Yellow "Creating new user: $ftpUsername / $ftpPassword / $ftpGroup"
#------------------------------------------
#---Create the folder structure
#------------------------------------------
Write-Host -ForegroundColor DarkYellow "Creating new folder at: \\$filezillaServer\$ftpDataShare\$ftpGroup\$ftpUsername"
if (!(Test-Path "\\$filezillaServer\$ftpDataShare\$ftpGroup\$ftpUsername")){
    $null = New-Item -ItemType directory -Path "\\$filezillaServer\$ftpDataShare\$ftpGroup\$ftpUsername" 
    $null = New-Item -ItemType directory -Path "\\$filezillaServer\$ftpDataShare\$ftpGroup\$ftpUsername\$ftpUsername"
    }
#------------------------------------------
#---Edit the FileZilla XML to add the new user
#------------------------------------------
Write-Host -ForegroundColor DarkYellow "Adding $ftpUsername to FileZilla"
$passHash = hashMeAPassword $ftpPassword

$newFZUser = ($xml.FileZillaServer.Users.User | ?{$_.Name -eq "TemplateFTPUser"}).clone() #Uses a template user called "TemplateFTPUser" that you've already created in FileZilla through the GUI
$newFZUser.Name = $ftpUsername
$newFZUser.SelectSingleNode("Option[@Name='Pass']").InnerText = $passHash
$newFZUser.SelectSingleNode("Option[@Name='Group']").InnerText = $ftpGroup
$newFZUser.SelectSingleNode("Option[@Name='Enabled']").InnerText = 1
$newFZUser.SelectSingleNode("Option[@Name='Comments']").InnerText = "Created by $env:username on $(get-date $date -Format "yyyy/MM/dd hh:mm:ss") updated by $env:username on $(get-date $date -Format "yyyy/MM/dd hh:mm:ss")"
$newfzuser.permissions.permission.dir = "$localPathToFTPDataShareOnFileZillaServer\$ftpDataShare\$ftpGroup\$ftpUsername"

$null = $xml.DocumentElement.Users.AppendChild($newFZUser)
$xml.Save($xmlFilePath)


#------------------------------------------
#---Reload the FileZilla config to initialise the new user
#------------------------------------------
Write-Host -ForegroundColor DarkYellow "Activating $ftpUsername ..."
Invoke-Command -ComputerName $filezillaServer -FilePath $reloadFZConfigCmdPath -ConfigurationName $psSessionConfigurationNameOnFileZillaServer


Write-Host -ForegroundColor Yellow "User setup complete! Press enter to exit this window"
$null = Read-Host
