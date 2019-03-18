#Script to reload the FileZilla config from "%PROGRAM FILES (x86)%\FileZilla Server\FileZilla Server.xml" without restarting the services.
#
#This should be saved and executed on the FileZilla Server
#
#Requirements:
#- This command requires local admin permissions on the FileZilla server
#
#If you like the script, feel free to pop a beer in the post c/o Kev Maitland - I work at the head office of www.sustain.co.uk :)

$reloadFZConfigCMD = '"C:\Program Files (x86)\FileZilla Server\FileZilla Server.exe" "/reload-config"'
iex "& $reloadFZConfigCMD"
Exit-PSSession #This automatically drops the PSSession, which reduces the possibility of abuse as the -RunAsCredentials account.
