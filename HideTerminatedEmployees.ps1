#Created By Tyler Roth
#Reviewd By Brian Brooks

#Names it erroed out on
$collectionOfBadNames = "gporter","kMurugan","mSubramanian","mthomas","rjuarez","sGanesan","sAbdul","tPerson1","vVeeramuthu","vChellamuthu"

$mailboxes = Get-ADUser -Filter * -SearchBase 'OU=~Terminated Employee,OU=Accounts,DC=2ndimage,DC=COM' -Searchscope 1 | Select samAccountName

$mailboxes | ForEach-Object {

#Changed To a not statement
if ($collectionOfBadNames -contains $_.samAccountName) {return}


#Add an nested if to see if it is not hidden from address list and then to hide it
Set-Mailbox -Identity $_.samAccountName -HiddenFromAddressListsEnabled $true

}