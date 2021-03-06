
#Region Functions

function local:Ensure-Folder
{
   param
   (
      [parameter(Mandatory=$true)][string]$Folder
   )
   
   if(!(Test-Path -Path $Folder))
   {
      Write-Host "Missing $($Folder) Required Folder, Creating..." -NoNewline
      New-Item -Path $Folder -ItemType Directory -Force
      Write-Host -ForegroundColor Yellow " Completed"
   }
   return
}

function local:Check-File 
{
   param
   (
      [parameter(Mandatory=$true)][string]$Folder,
      [parameter(Mandatory=$true)][string]$File
   )
   $Return = $false
   $Chk_File = "$($Folder)\$($File)"
   Write-Host "Checking for `n   <$($Chk_File)>" -NoNewline
   if((Test-Path -Path $Chk_File))
      { $Return = $true }
   if($Return){Write-Host "Found" -ForegroundColor Yellow} else {Write-Host " Missing" -ForegroundColor Red}
   Return $Return
}

#EndRegion

[string]$ScriptFolder = (get-location).Path
[string]$JSON_Frag_Folder = ($ScriptFolder + "\JSON_Fragments\")

[string]$JSON_OutFile = $ScriptFolder + "\JSON_OUT"
[string]$RunTime_OutFile = $ScriptFolder + "\RunTime_OUT"

if(!(Test-Path -Path $JSON_Frag_Folder))
{
   Write-Host "Missing Required Folder!! Execution halted"
   return
}

$File_LKUP = "conversions.csv"
if(!(Check-File -Folder $ScriptFolder -File $File_LKUP))
{
   Write-Host " Execution halted" -ForegroundColor Yellow
   return
}

$Files_JSON = @()
$Files_JSON += "Resource_Fragment.json"
$Files_JSON += "BaseVM_Fragment-c.json"
$Files_JSON += "DataDisk_Fragment.json"
$Files_JSON += "OSDisk_Create_Fragment.json"
$Files_JSON += "OSDisk_Attach_Fragment.json"
for ($index = 0; $index -lt $Files_JSON.count; $index++) {
	Write-Host $Files_JSON[$index] -NoNewline
   Write-Host (Check-File -Folder $JSON_Frag_Folder -File $Files_JSON[$index])
}


## Runtime Folders
#Ensure-Folder -Folder $JSON_OutFile
#Ensure-Folder -Folder $RunTime_OutFile
