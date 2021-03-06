<#
 * Copyright Microsoft Corporation
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
#>

[CmdletBinding()]
Param
   (
      [parameter(Mandatory=$false)][string]$ConverFile = "conversions.csv",
      [parameter(Mandatory=$false)][string]$ScriptFolder = (get-location).Path
   )
   
$ErrorActionPreference = 'Stop'
trap {
'Error Category {0}, Error Type {1}, ID: {2}, Message: {3}' -f  $_.CategoryInfo.Category, $_.Exception.GetType().FullName,  $_.FullyQualifiedErrorID, $_.Exception.Message
return
}

# Set path to shared functions
##Load the functions
Import-Module $scriptFolder\SharedComponents\ARMRedeployFunctions.psm1 -AsCustomObject -Force -DisableNameChecking -Verbose:$false

#$InAccounts = Import-Csv -Path ("$($ScriptFolder)\conversions.csv") |  where {$_.source -like "*store*"} | select destination -Unique
$InAccounts = Import-Csv -Path ("$($ScriptFolder)\$($ConverFile)") |  where {$_.source -like "*store*"} | select destination -Unique

#Region Variables
[string]$JSON_Frag_Folder = ($ScriptFolder + "\JSON_Fragments\")
$JSON_Storage_Tag = "[*Storage Frag*]"
$First_Time=$true

$JSON_StorageAcct_Fragment = "$($JSON_Frag_Folder)StorageAcct_Fragment.json"
#EndRegion

Write-Host "`nProcessing... $($InAccounts.count) Storage Account(s)" 
foreach($InAccount in $InAccounts)
{
   write-host $InAccount.destination
   if(!$First_Time){$JSON_Out[$JSON_Out.Length-1] = $JSON_Out[$JSON_Out.Length-1].replace("}","},")}
   $First_Time=$false

   $JSON = $JSON_StorageAcct_Fragment

Write-Host $JSON

   ## Update JSON with Derived values
   $JSON = $JSON.Replace("[*StorageName*]",$InAccount.destination)
}


Write-Host $JSON
#
#$JSON_Out[$JSON_Out.Length-1] = $JSON_Out[$JSON_Out.Length-1].replace("},","}")
#$JSON_Out | Out-File -FilePath $Frag_OutFile -Encoding string
#Write-Host -ForegroundColor Yellow " ...Complete" 
#
#Write-Host "Writing CS resource file..."  
#$JSON_Storage = $null ; $JSON_Storage = Get-Content ("$($ScriptFolder)\$($JSON_Frag_Folder)\Storage_Fragment.json")
#
#$JSON_Storage = $JSON_Storage.Replace("[*Location*]",$JSON_Dep_Location)
#$JSON_Storage = $JSON_Storage.Replace("[*DepNetwork*]",$JSON_Dep_Network)
#$JSON_Storage = $JSON_Storage.Replace("[*DepResGrp*]",$JSON_Dep_ResGrp)
#
#Write-Host "   <$($JSON_Storage_Tag)>$($Frag_OutFile)" -NoNewline 
#$xx = (Insert-Fragment -Src_Frag $JSON_Storage -Frag_Key $JSON_Storage_Tag -Frag_Content (Get-Content ($Frag_OutFile)) -Status $true)
#$xx | Out-File -FilePath $Resouce_OutFile -Encoding string

Write-Host -ForegroundColor Yellow " ...Complete"
