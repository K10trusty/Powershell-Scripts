
#cURRENTLY ITEL-USERS.txt will have to be genereaclear-hostted by you or will have to find a direcotry where this txt file can live
Get-content "MULTIPLE-TERM-Users.txt" | foreach-object {
$SplitName = -split $_

$GivenName = $SplitName[0]
$SurName = $SplitName[1]
Write-Host "Getting SamAccount Name"

$usersamaccount = Get-ADUser -Filter {(GivenName -eq $GivenName) -and (Surname -eq $SurName)} -SearchBase "OU=Ditry,OU=Vendors,OU=Accounts,DC=Conosto,DC=com" -SearchScope 1 | Select-Object SamAccountName

write-host $usersamaccount
##Removing formatting and getting the raw name
$rawSamAccount = $usersamaccount.SamAccountName

Write-Host "Setting out to disable AD account...."
Disable-ADAccount -Identity $rawSamAccount
Write-Host "Account is Disabled"

Write-Host "Starting to change the Primary Group of $_"
$Group = get-adgroup "CN=SIG-ActiveSyncDisabled,CN=Users,DC=Conosto,DC=com" -properties @("primaryGroupToken")
Set-ADUser -Identity $rawSamAccount -Replace @{primarygroupid=$group.primaryGroupToken}
Write-Host "Changes Complete"

Write-Host "Moving account to the ~Terminated Employee OU"
##Need to get the GUID of user for the move object
$adUserDistinguishedName = Get-ADUser -Identity $rawSamAccount -Properties * | Select DistinguishedName
##Moves the account to the Terminated folderclea
Move-AdObject -Identity $adUserDistinguishedName -TargetPath "OU=~Terminated Employee,OU=Accounts,DC=Conosto,DC=com"
Write-Host "Account Move Complete!"



Write-host "Getting Ready To Remove from all groups"
##ARRAY To select which groups to Remove the user from
$removeList = @(
  'CN=Group1,OU=Groups,DC=Conosto,DC=com',
  'CN=Group2,OU=Dirty,OU=Vendors,OU=Accounts,DC=Conosto,DC=com',
  'CN=Group3,CN=Users,DC=Conosto,DC=com')

#This removes the user from all groups listed in $removeList
$grps = Get-ADUser $rawSamAccount -Properties memberof | select -expand memberof
#remove all except $keep

$grps | Where-Object {$removelist -eq $_} | Remove-ADGroupmember -Members $rawSamAccount

#Future Work
#Add Check both SIRUS and MR8 and remove them from those
#kill active login session to RDS


Write-Host $_ "Either Complete or Incomplete"
Write-host "=================================================="

##Freeing up the Varibles here at the end for use with the next loop
$rawSamAccount = ""
$usersamaccount =""
$GivenName = ""
$SurName = ""

 }

