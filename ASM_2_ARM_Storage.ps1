

[string]$ScriptFolder = (get-location).Path
[string]$JSON_Frag_Folder = ($ScriptFolder + "\JSON_Fragments\")

$InAccounts = Import-Csv -Path ("$($ScriptFolder)\conversions.csv") |  where {$_.source -like "*store*"} | select destination -Unique

#Region Variables
$JSON_Storage_Tag = "[*Storage Frag*]"
$First_Time=$true

#EndRegion

Write-Host "`nProcessing... $($InAccounts.count) Storage Account(s)" 
foreach($InAccount in $InAccounts)
{
   write-host $InAccount.destination
   if(!$First_Time){$JSON_Out[$JSON_Out.Length-1] = $JSON_Out[$JSON_Out.Length-1].replace("}","},")}
   $First_Time=$false
}

$JSON_Out[$JSON_Out.Length-1] = $JSON_Out[$JSON_Out.Length-1].replace("},","}")
$JSON_Out | Out-File -FilePath $Frag_OutFile -Encoding string
Write-Host -ForegroundColor Yellow " ...Complete" 

Write-Host "Writing CS resource file..."  
$JSON_Storage = $null ; $JSON_Storage = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "Storage_Fragment.json")

$JSON_Storage = $JSON_Storage.Replace("[*Location*]",$JSON_Dep_Location)
$JSON_Storage = $JSON_Storage.Replace("[*DepNetwork*]",$JSON_Dep_Network)
$JSON_Storage = $JSON_Storage.Replace("[*DepResGrp*]",$JSON_Dep_ResGrp)

Write-Host "   <$($JSON_Storage_Tag)>$($Frag_OutFile)" -NoNewline 
$xx = (Insert-Fragment -Src_Frag $JSON_Storage -Frag_Key $JSON_Storage_Tag -Frag_Content (Get-Content ($Frag_OutFile)) -Status $true)
$xx | Out-File -FilePath $Resouce_OutFile -Encoding string

Write-Host -ForegroundColor Yellow " ...Complete"
