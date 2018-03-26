<#

Author: Phil Wray
Version:1.0

Purpose: Give user full access to another mailbox, without loading it in outlook (automapping)

#>
$User = Read-Host 'Enter email of who wants access'
$Access = Read-Host 'Enter email of the mailbox they are accessing'
$Level = 'FullAccess'
Add-MailboxPermission -Identity $Access -User $User -AccessRights $Level -InheritanceType All -Automapping $false
