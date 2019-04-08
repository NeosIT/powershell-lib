Connect-ExchangeServer -auto; 
$all = Get-MailboxStatistics -Server nova.ad.neos-it.de | Where { $_.LastLogonTime -gt (Get-Date).AddMonths(-3)}; 

# Benutzer mit englischem Exchange Online
$all | ForEach-Object { set-MailboxFolderPermission -Identity "$($_.DisplayName):\Calendar\" -User Default -AccessRights 'Reviewer'}
# Benutzer mit deutschem Exchange Online
$all | ForEach-Object { set-MailboxFolderPermission -Identity "$($_.DisplayName):\Kalender\" -User Default -AccessRights 'Reviewer'}
