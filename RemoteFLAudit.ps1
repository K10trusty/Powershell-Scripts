####################################################################################################
#Read List of servers from a Text file and fetch all local users from the servers mentioned in it. #
#List of local users from servers is exported in CSV file at the same location.                    #
#Written by Prakash Kumar 12:58 PM 8/5/2015                                                        #
####################################################################################################
import-module activedirectory

#function getBitInfo
#{
#    BEGIN
#    {
#        #Build the base object
#        $bitObj = New-Object -TypeName PSObject -Property @{PercentageEncrypted="";ProtectionStatus=""}

#    }
#    PROCESS
#    {
#
        #If the line contains the status pull that out.
#        if($_ -match 'Percentage Encrypted:')
#        {
#            $PercentageEncrypted = ($_ -split ":")[1].trim()
#            $bitObj.PercentageEncrypted = $PercentageEncrypted
#        }
#        if($_ -match 'Protection Status:')
#        {
#            $ProtectionStatus = ($_ -split ":")[1].trim()
#            $bitObj.ProtectionStatus = $ProtectionStatus
#        }
#    }
#    END
#    {
        #write out the completed object
#        Write-Output $bitObj
#    }
#}

#Gets a list from AD looking at the Florida OU
#Writes it to a text file called Servers.txt
Get-Adcomputer -Filter * -SearchBase 'OU=Computers,DC=2ndimage,DC=com' | Select-Object -expandproperty Name | Format-Table -HideTableHeaders | Out-file "Servers.txt"

get-content "Servers.txt" | foreach-object {
    $comp = $_
	if (test-connection -computername $Comp -count 1 -quiet)
{

                    ([ADSI]"WinNT://$comp").Children | ?{$_.SchemaClassName -eq 'user'} | %{
                    $groups = $_.Groups() | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
                    $_ | Select @{n='Server';e={$comp}},
                    @{n='Bitlocker Status';e={manage-bde.exe -status c: -ComputerName $Comp Select-String "Conversion Status:","Volume"}},
                    @{n='UserName';e={$_.Name}},
                    @{n='Active';e={if($_.PasswordAge -like 0){$false} else{$true}}},
                    @{n='PasswordExpired';e={if($_.PasswordExpired){$true} else{$false}}},
                    @{n='PasswordAgeDays';e={[math]::Round($_.PasswordAge[0]/86400,0)}}
                    
                 } 
           } Else {Write-Host "'$Comp' is Unreachable, Could not fetch data"
                   Write-Host Get-ADComputer $_ -Properties lastLogonDate | Select LastLogonDate}
     }|Export-Csv -NoTypeInformation LocalUsers.csv 