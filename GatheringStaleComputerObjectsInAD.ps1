$Date = [DateTime]::Today.AddDays(-365) 
Get-ADComputer -SearchBase "OU=Servers,OU=Assets,DC=2ndimage,DC=com" `
-Filter '(ObjectClass -eq "Computer") -And (LastLogonDate -lt $Date) -Or (pwdLastSet -lt $Date)' `
-Properties pwdLastSet,LastLogonDate | Select-Object Name,`
@{Name="LastLogonTimeStamp";Expression={[datetime]::FromFileTime($_.LastLogonTimeStamp)}}, `
@{Name="PwdLastSet";Expression={[datetime]::FromFileTime($_.PwdLastSet)}}, `
DistinguishedName,SamAccountName,DNSHostName,ObjectClass,Enabled,ObjectGUID | `
Export-CSV -Path .\StaleServerObjects.csv