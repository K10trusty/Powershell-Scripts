
#Values to Hold the Mail Servers to connect to
$mail1 = "your mail server"
$mail2 = "Something Soon"

function Show-Menu
{
    Param (
        [string]$MenuTitle='Add/Modify Mailbox Permissions'
        )
        Write-Host "==========================$MenuTitle=========================="
        Write-Host " 1: Enter ' 1' to grant FullAccess permission to a Mailbox"
        Write-Host " 2: Enter ' 2' to grant Send on-behalf of permission to a Mailbox"
        Write-Host " 3: Enter ' 3' to grant FullAcess and Send On-behalf of permissions to a Mailbox"
        Write-Host " 4: Enter ' 4' to remove FullAccess permission to a Mailbox"
        Write-Host " 5: Enter ' 5' to remove Send on-behalf of permission to a Mailbox"
        Write-Host " 6: Enter ' 6' to remove FullAcess and Send On-behalf of permissions to a Mailbox"
        Write-Host " 7: Enter ' 7' to list Mailbox Permissions"
        Write-Host " 8: Enter ' 8' to list all Mailboxes that a user has been granted access to"
        write-Host " 9: Enter ' 9' to list Mailbox Rules"
        Write-Host "10: Enter '10' to list all Distribution Groups account is a member of"
        Write-Host "11: Enter '11' to list Distribution Group Members"
        Write-Host "12: Enter '12' to list Nested Distribution Group Members"
        Write-Host "14: Enter '14' to list all Room Resource Mailboxs"
        Write-Host "15: Enter '15' to list all Equipment Mailboxs"
        Write-Host "16: Enter '16' to create a Room Resource Mailbox"
        #The following are out of order but rewrite needed for post exch migration#
        Write-Host "17: Enter '17' to grant Send As permission to mailbox"
}

function Get-NestedGroupMember 

  {
  [CmdletBinding()] 
  param 
  (
    [Parameter(Mandatory)] 
    [string]$Group 
  )
  
  ## Find all members  in the group specified 
  
  $members = Get-ADGroupMember -Identity $Group 
  foreach ($member in $members)
  {

  ## If any member in  that group is another group just call this function again 
  
  if ($member.objectClass -eq 'group')
  {
  Write-Host $member.Name
  Write-Host "------------------"
  Get-NestedGroupMember -Group $member.Name
  Write-Host ""
  }

  else ## otherwise, just  output the non-group object (probably a user account) 

  {
  $member.Name  
  }
  }
  }

#I only run this script when I want to connect
#$ConnectTo = Read-Host "Do you need to connect to Exhcnage (y/N)"

#If ($ConnectTo -eq 'y') {

$UserCredential = Get-Credential
#Reads Menu Options to User about which email to connect to
 $ans = Read-Host "==========================Choose Which Email Server To Connect To==========================
    1: Enter ' 1' to access $mail1
    2: Enter ' 2' to access $mail2
    3: Enter ' 3' to enter it Manually `n"

switch ($ans)
{
  '1'{
      $ExchServer = $mail1
  } 
  '2'{
      $ExchServer = $mail2
  }
  '3'{
     $ExchServer = Read-Host -Prompt 'Exchange Server FQDN'
  }
  }


#Checks for an opened PsSession and if its open do nothing, if no open session, open one
if(Get-PsSession | Where State -eq 'Opened'){ 
     # we still are connected and availablere
}else{
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServer/PowerShell -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session
}

#}

do
{
    Show-Menu
    $PickNumber = Read-Host "Please make a selection"
    switch ($PickNumber)
    {
    '1'{
        $GrantTo = Read-Host -Prompt 'Who needs mailbox access? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they need access to? (e-mail address)'
        Add-MailboxPermission -Identity $GrantOn -User $GrantTo -AccessRights FullAccess -InheritanceType All -AutoMapping $false
        Get-MailboxPermission -Identity $GrantTo | where {$_.IsInherited -eq $false} | ft -autoSize User,Identity,AccessRights,IsInherited
    }'2'{
        $GrantTo = Read-Host -Prompt 'Who needs mailbox access? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they need access to? (e-mail address)'
        Set-mailbox $GrantOn –Grantsendonbehalfto @{add=$GrantTo}
        Get-Mailbox $GrantOn | ft -autosize -wrap Identity,GrantSendonbehalfto

    }'3'{
        $GrantTo = Read-Host -Prompt 'Who needs mailbox access? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they need access to? (e-mail address)'
        Add-MailboxPermission -Identity $GrantOn -User $GrantTo -AccessRights FullAccess -InheritanceType All -AutoMapping $false
        Set-mailbox $GrantOn –Grantsendonbehalfto @{add=$GrantTo} | ft User,Identity,AccessRights
        Get-MailboxPermission -Identity $GrantOn | where {$_.IsInherited -eq $false} | ft -autoSize User,Identity,AccessRights,IsInherited
        Get-Mailbox $GrantOn | ft -autosize -wrap Identity,GrantSendonbehalfto
    }'4'{
        $GrantTo = Read-Host -Prompt 'Whos mailbox access rights to remove? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they no longer need access to? (e-mail address)'
        Remove-MailboxPermission -Identity $GrantOn -User "$GrantTo" -AccessRights FullAccess,DeleteItem -InheritanceType All
        Get-MailboxPermission -Identity $GrantOn | where {$_.IsInherited -eq $false} | ft -autoSize User,Identity,AccessRights,IsInherited
    }'5'{
        $GrantTo = Read-Host -Prompt 'Whos mailbox access rights to remove? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they no longer need access to? (e-mail address)'
        Set-Mailbox -Identity $GrantOn -GrantSendOnBehalfTo @{remove=$GrantTo}
        Get-Mailbox $GrantOn | ft -autosize -wrap Identity,GrantSendonbehalfto
    }'6'{
        $GrantTo = Read-Host -Prompt 'Whos mailbox access rights to remove? (e-mail address)'
        $GrantOn = Read-Host -Prompt 'Mailbox they no longer need access to? (e-mail address)'
        Remove-MailboxPermission -Identity $GrantOn -User "$GrantTo" -AccessRights FullAccess,DeleteItem -InheritanceType All
        Set-Mailbox -Identity $GrantOn -GrantSendOnBehalfTo @{remove=$GrantTo}
        Get-MailboxPermission -Identity $GrantOn | where {$_.IsInherited -eq $false} | ft -autoSize User,Identity,AccessRights,IsInherited
        Get-Mailbox $GrantOn | ft -autosize -wrap Identity,GrantSendonbehalfto
    }'7'{
        $GrantOn = Read-Host -Prompt 'List users with access to who? (e-mail address)'
        Get-MailboxPermission -Identity $GrantOn | where {$_.IsInherited -eq $false} | ft -autoSize User,Identity,AccessRights,IsInherited
        Write-Host "======Send on Behalf Permissions======"
        Get-Mailbox $GrantOn | Select -ExpandProperty GrantSendOnBehalfto
        #ft -autosize -wrap Identity,GrantSendonbehalfto
    }'8'{
        $GrantTo = Read-Host -Prompt 'User to list Mailboxes that they have access to (e-mail address)'
        Get-Mailbox | Get-MailboxPermission -User $GrantTo | ft -autoSize User,Identity,AccessRights,IsInherited
        $objMailboxs = Get-Mailbox -ResultSize Unlimited
        $objGranton = Get-Mailbox -Identity $GrantTo
        Write-Host "======Send on Behalf Permissions======"
        Foreach ($objMailbox in $objMailboxs)
        {
            if ($($objMailbox.GrantSendOnBehalfTo) -ne $null)
            {
                $objSendOnBehalfUsers = Get-Mailbox -Identity $($objMailbox.DisplayName) | Select -ExpandProperty GrantSendonbehalfto
                Foreach ($objSendOnBehalfUser in $objSendOnBehalfUsers) 
                {
                if ($($objSendOnBehalfuser) -eq $($objGrantOn.Identity)){
                    Write-Host -ForegroundColor white "$($objMailbox.Identity)"}
                }
            }
        }
    }'9'{
        $Granton = Read-Host -Prompt 'Mailbox to list rules (e-mail address)'
        Get-InboxRule -IncludeHidden -Mailbox $GrantOn | ft -autoSize Name,Enabled,Priority,RuleIdentity
    }'10'{
        $Groups=@()
        $GrantOn = Read-Host -Prompt 'User to list Distributin Groups that user is member of (e-mail address)'
        $User = get-mailbox -Identity $GrantOn; 
        Get-DistributionGroup | foreach {
            $dg = $_.Name
            Get-DistributionGroupMember $dg | foreach {if ($_.identity -eq $User.identity) {$Groups += $DG}}
        }
        $Groups
    }'11'{
        $GrantOn = Read-Host -Prompt 'Distribution Group to list members of (Group Name)'
        Get-DistributionGroupMember $GrantOn | ft -AutoSize Name,RecipientType
    }'12'{
        $GrantOn = Read-Host -Prompt 'Distribution Group to list members of (Group Name)'
        Get-NestedGroupMember $GrantOn
    }'14'{ 
        Get-Mailbox -RecipientTypeDetails RoomMailbox | ft Name
    }'15'{
        Get-Mailbox -RecipientTypeDetails EquipmentMailbox | ft Name
    }'16'{
        $MBAlias = Read-Host -Prompt 'Short Name of the resource mailbox (Must not have spaces)'
        $DN = Read-Host -Prompt 'Mailbox display Name'
        $PSMTP = Read-Host -Prompt 'Primary SMTP address of the resource mailbox'
        ## Only start using this if we need to control who can view resource calendar##
        ## $RMViewers = Read-Host -Prompt 'E-mail address of the Group that needs access to the resource calendar' ##
        $RMOwner = Read-Host -Prompt 'E-mail address of the resource calendar manager'

        ## Create the resource mailbox ##

        New-Mailbox -Name $MBAlias -DisplayName $DN -OrganizationalUnit '2ndimage.com/Accounts/Resources' -PrimarySmtpAddress $PSMTP -Room

        ## Configure the resource mailbox calendar##
        
        Set-CalendarProcessing -Identity $PSMTP -AutomateProcessing AutoAccept -AllowRecurringMeetings $true -AllowConflicts $true -ConflictPercentageAllowed 100 -MaximumConflictInstances 10  -MaximumDurationInMinutes 0 -BookingWindowInDays 365 -EnforceSchedulingHorizon $False -AddOrganizerToSubject $true -DeleteComments $false -DeleteSubject $false

        ## Configure permissions of the resource mailbox calendar##

        Set-MailboxFolderPermission -Identity $PSMTP':\calendar' -User default -AccessRights reviewer

        ## Grant Full Calendar Control to Manager ##

        Add-MailboxFolderPermission -Identity $PSMTP':\calendar' -User $RMOwner -AccessRights PublishingEditor

        ## Display the results ##

        Get-Mailbox -Identity $PSMTP | fl Name,DisplayName,PrimarySmtpAddress
        Get-CalendarProcessing -Identity $PSMTP | fl AutomateProcessing,AllowRecurringMeetings,AllowConflicts,ConflictPercentageAllowed,MaximumConflictInstances,MaximumDurationInMinutes,BookingWindowInDays,EnforceSchedulingHorizon,AddOrganizerToSubject,DeleteComments,DeleteSubject
        Get-MailboxFolderPermission -Identity $PSMTP':\calendar' | FL
    }'17'{
    Write-Host "Not Ready Yet..."
    #Command to base this part On#
    #Get-Mailbox "Help Desk" | Add-ADPermission -User "Help Desk Team" -ExtendedRights "Send As"#
    }
   }
   $PickNumber = Read-Host "Enter to contiune or 'Q' to quit"
  }
until ($PickNumber -eq 'q')

If ($ConnectTo -eq 'y') {Remove-PSSession $Session}