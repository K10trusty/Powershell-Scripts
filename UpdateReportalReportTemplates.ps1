#Made By: Tyler Roth

#Define Basic starting path
$reportalPath = "\\some\UNC\Path\CopyTo"


#This Function will only list folders and not .rpt files
function ListFoldersOnly {
    Param([string]$reportalPath)

#Grab the File Structure and add to it
$selectFile = Get-ChildItem -Force $reportalPath -ErrorAction SilentlyContinue | ?{ $_.PSIsContainer }

$menu = @{}
Write-Host "************************************************************************************************ `n
You are here $reportalPath"
for ($i=1;$i -le $selectFile.count; $i++) {

#commet out this do while statement to not be cosntraiend to 20 lines
 #   if ($i -gt 20) {
 #   Write-Host "To Many Items, Only Display the first 20"
 #   break
 #   }

    Write-Host "$i. $($selectFile[$i-1].name)"
    $menu.Add($i,($selectFile[$i-1].name))
    }
    [int]$ans = Read-Host 'Enter Number of the file to select'
    $selection = $menu.Item($ans)
    Write-Host "You have chosen $selection"
    $reportalPath = Join-Path -Path $reportalPath -ChildPath $selection
    return $reportalPath
    "`n"
}

function ListRptFilesOnly {
    Param([string]$reportalPath)

#Grab the File Structure and add to it
$selectFile = Get-ChildItem $reportalPath* -include *.rpt -force -recurse | Sort-Object

$menu = @{}
$nameMenu = @{}
Write-Host "************************************************************************************************ `n
You are here $reportalPath"
for ($i=1;$i -le $selectFile.count; $i++) {

#commet out this do while statement to not be cosntraiend to 20 lines
 #   if ($i -gt 20) {
 #   Write-Host "To Many Items, Only Display the first 20"
 #   break
 #   }
    ## Displaying the Filename
    Write-Host "$i. $($selectFile[$i-1].name)"

    ## Saving the full FilePath. Makes it easier to read if it dosent display
    $menu.Add($i,($selectFile[$i-1].fullname))
    $nameMenu.Add($i,($selectFile[$i-1].name))
    }
    [int]$ans = Read-Host 'Enter Number of the file to select'
    $selection = $menu.Item($ans)
    $nameSelection = $nameMenu.Item($ans)

    #Let User Know what They have selected
    Write-Host "You have chosen $nameSelection"
    return $selection, $nameSelection

}


#Main Function this is what gets exectured here

###[1]### Have User Select Which File - Done
###[2]### Copy The File to a directory for backups just in case - Done
###[3]### Upload the file from downloads to the Correct Directory in Crystal Reports
###[4]### Run the Crystal Reports and Check for errors
###[5]### Ask user if report looks okay or if on error revert to the previous file


#This updates the reportalPath in the function and saves it back to the reportal Variable

###[1]###
$reportalPath = ListFoldersOnly $reportalPath

Write-Host $reportalPath
Write-Host $fileName
#This crawls the Crystal Reports folder structure and recusively searches all items and only returns .rpt items
$reportDirectory = ListRptFilesOnly $reportalPath

###[2]###
WRite-Host "`n Full File Path" $reportDirectory[0]
Write-Host "`n beep-Boop" $reportDirectory[1]
Write-Host "`n Copying To Shared Drive of Tyler Roth on Reprotal Server `n"
Write-Host "`n***************************************************************
`n Find the File here \\2ndimage\users\Home\tRoth\OldReportalFiles 
`n*************************************************************** `n"

Copy-Item $reportDirectory[0] -Destination "\\My\users\Home\tRoth\OldReportalFiles"

Write-Host "`n Done Copying!! `n"

###[3]###
Write-Host "`n`n Please Select File to Upload to the Directory `n
This searchers for RPT files in the downloads folder`n`n"

#Replacing the reportal directory path with users own dowload folder
$reportalPath = $env:USERPROFILE + "\Downloads"
$downloadDirectory = ListRptFilesOnly $reportalPath




#************************************************************************************************#
####******When Ready to Deply Change Copy-Item from Static Set to $reportDirectory *******########
#************************************************************************************************#
Copy-Item $downloadDirectory[0] -Destination $reportDirectory[0]

Write-Host "Updated Succesfully!! `n Please check the reporti n reportal now"
###[4]###

##Connect to Reportal (Crystal Reports) run a report to check it



