$ClientComputer= Read-Host -Prompt 'Input computer name to check logged on user'
Get-WmiObject –ComputerName $ClientComputer –Class Win32_ComputerSystem | Select-Object UserName