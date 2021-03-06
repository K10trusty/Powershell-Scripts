
#*******************************************************************************************
#-------------------
# Made By Tyler Roth
#-------------------
#*******************************************************************************************
#BE SURE TO CREATE A POWERSHELL SESSION WITH EXCHAGNE FOR THE HIDEING OF THE USER FROM THE GAL
#********************************************************************************************
#BACKLOG: 
#Add in option to import from list
#Add in Exhcnage shell create or checking for it
#Add in a check for are you sure when selecting from multiple users
#When remivng AD groups dont have to click the confirm Yes TO all.
#add Directly to DC so it dosent take ~5minutes to propogate


import-module activedirectory

$ExchServer = 'mailserver Record'

#Checks to see if we have an active PSSession, if there is an open one, do nothing
if(Get-PsSession | Where State -eq 'Opened'){ 
     #DO nothing

}else{
$UserCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServer/PowerShell -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session
}

#Grabs the User Name
$name = Read-Host -Prompt "Enter the Terminatied Employees Name (Partial Names Work as Well)"
Write-Host "Lookin up person of interest"

#Get Fullusername
$full_name = "*$name*"
Write-Host "Processing"
$user = Get-ADuser -Filter {name -like $full_name} | Select-Object name,SamAccountName | Sort-Object name

#Checking for Mutiple Usernames
#Grabbing Mutiple Usernames
#Menu to display which user to be terminated

#Checking to see if there is just one name that matches it (Wont need to do menu and selection)
if ($user.count -lt 2) {
Write-Host "$user"
write-host -nonewline "Continue? (Y/N) "

#Ask if the one username is the correct name
$response = read-host
if ( $response -ne "Y" ) { exit }
    $selection = $user.samAccountName
    
    #Uncomment this if you want the file to display the persons name
    #$write_selection = $user.name
    #Grabbing the Groups they are before we remove them and logging it somewhere
    #Right now its statically set for logging
    #Need some error handling if file exists to not overwrite but add 1 to it and print it out to console, NoClobber is turned off
Get-ADPrincipalGroupMembership $selection | select name | Out-File -filepath C:\Users\troth\Desktop\$selection.txt #-NoClobber
$emailList = Get-ADPrincipalGroupMembership $selection | select name | Out-String
$termUsername = $selection
    Write-Host "$selection"
   # Exit
 } else {
 
 #Initlizing the Array
$menu = @{}
Write-Host "I found some people, not sure which one"
for ($i=1;$i -le $user.count; $i++) {

#commet out this statement to not be cosntraiend to 20 lines
    if ($i -gt 20) {
    Write-Host "To Many Items, Only Display the first 20"
    break
    }

    Write-Host "$i. $($user[$i-1].name)"
    $menu.Add($i,($user[$i-1].samAccountName))
    } 


# This shows the Full Name and Grabs the samAccountName
[int]$ans = Read-Host 'Enter Number of person to terminate'
$selection = $menu.Item($ans)

#Uncomment this if you want the file to display the persons name
#$write_selection = $user.name
#Grabbing the Groups they are before we remove them and logging it somewhere
#Right now its statically set for logging
#Need some error handling if file exists to not overwrite but add 1 to it and print it out to console, NoClobber is turned off
Get-ADPrincipalGroupMembership $selection | select name | Out-File -filepath C:\Admin\Logs\$selection.txt #-NoClobber
$emailList = Get-ADPrincipalGroupMembership $selection | select name | Out-String
$termUsername = $selection
Write-Host "$selection"
}

##ARRAY To select which groups to keep the user in
$keep = @(
  'CN=Group1,CN=Users,DC=Conosto,DC=com',
  'CN=Group2,CN=Users,DC=Conosto,DC=com',
  'CN=Group3,CN=Users,DC=Conosto,DC=com',
  'CN=Group4,CN=Users,DC=Conosto,DC=com')

##Sets the account to disabled using the samAccountname

Write-Host "Setting out to disable AD account...."
Disable-ADAccount -Identity $selection
Write-Host "Account is Disabled"

#Need to get the GUID of user for the move object
$adUserDistinguishedName = Get-ADUser -Identity $selection -Properties * | Select DistinguishedName

##Moves the account to the Terminated folder
Write-Host "Moving account to the ~Terminated Employee OU"
Move-AdObject -Identity $adUserDistinguishedName -TargetPath "OU=~MovedOU,OU=Accounts,DC=Conosto,DC=com"

#This one hides the user from the Global Address List
Write-Host "Hiding this users from the Global Address List"
Set-Mailbox -Identity $selection -HiddenFromAddressListsEnabled $true

#This removes the user from all groups except those listed in $keep
$grps = Get-ADUser $selection -Properties memberof | select -expand memberof


#Write-Host "This will Error Out on the Domain Users, Dont Worry :)"
##Removes user from Distribtuion Groups
Write-Host "Removing User from The Correct AD Groups"

#remove all except $keep

$grps | Where-Object {$keep -notcontains $_} | Remove-ADGroupmember -Members $selection


#Send out email If Need be
#***********************************************************************************************************
#Sending out email with list of user permissions
Write-Host "Sending out Email to tdawg@Conosto.com about the groups they belonged to"
send-mailmessage -To "tdawg@Conosto.Com" -From "Terminated_User@Conosto.com" -Subject "Terminated $termUsername" -Body $emailList -SmtpServer mail.Conosto.com