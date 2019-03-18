#Script to configure a PSSessionConfiguration to allow remote users to run the /reload-config command locally on the FileZilla server
#When this script is run, the end-users who will be modifying FileZilla accounts need to be granted Execute(Invoke) permissions. These can be restricted by using a specific Security Group, or can be granted generally by adding the "Domain Users" Security Group
#This alleviates the need for end-users to be local administrators on the FileZilla server by granting them elevated privileges in a restricted way
#
#This should be executed once on the FileZilla Server (and run again whenever the $filezillaServerLocalAdmin password changes)
#
#Requirements:
#- The RunAsCredential account needs to be a local administrator (otherwise the /reload-config command will fail)
#- The password needs to be provided in Plain Text here
#- The $psSessionConfigurationNameOnFileZillaServer value should match the value used in the NewUser / ResetUser scripts
#
#If you like the script, feel free to pop a beer in the post c/o Kev Maitland - I work at the head office of www.sustain.co.uk :)


$filezillaServer = "yourFileZillaServer"
$filezillaServerLocalAdmin = "yourDedicatedLocalAdminAccountForFileZilla"
$filezillaServerLocalAdminPlainTextPassword = 'yourNiceLongSecurePassword'
$pathToReloadConfigScript = "C:\Program Files (x86)\FileZilla Server\"
$reloadConfigScriptName = "ReloadConfig.ps1"
$psSessionConfigurationNameOnFileZillaServer = "FileZilla"



Set-PSSessionConfiguration -Name $psSessionConfigurationNameOnFileZillaServer -ApplicationBase $pathToReloadConfigScript -RunAsCredential $(New-Object -TypeName System.Management.Automation.PSCredential "$filezillaServer\$filezillaServerLocalAdmin", $(ConvertTo-SecureString -String $filezillaServerLocalAdminPlainTextPassword -AsPlainText -Force)) -ShowSecurityDescriptorUI -StartupScript "$pathToReloadConfigScript\$reloadConfigScriptName"
