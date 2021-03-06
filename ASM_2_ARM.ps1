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
      [parameter(Mandatory=$false)][bool]$CreateOS = $true,
      [parameter(Mandatory=$false)][bool]$AttachData = $true,
      [parameter(Mandatory=$false)][bool]$PubIP = $false,
      [parameter(Mandatory=$false)][string]$ScriptFolder = (get-location).Path,
      [parameter(Mandatory=$false)][string]$imageFamilyName = "Windows Server 2012 R2 Datacenter"
   )
   
$ErrorActionPreference = 'Stop'
trap {
'Error Category {0}, Error Type {1}, ID: {2}, Message: {3}' -f  $_.CategoryInfo.Category, $_.Exception.GetType().FullName,  $_.FullyQualifiedErrorID, $_.Exception.Message
return
}


#Region Variables
$JSON_VM_Fragment = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "BaseVM_Fragment-c.json")
if($CreateOS)
{ $JSON_OSDisk_Fragment = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "OSDisk_Create_Fragment.json") }
else
{ $JSON_OSDisk_Fragment = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "OSDisk_Attach_Fragment.json") }

$JSON_DataDisk_Fragment = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "DataDisk_Fragment.json")
$JSON_Resource_Fragment = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "Resource_Fragment.json")
$JSON_VM_Tag = "[*VM Frag*]"
$JSON_OSDisk_Tag = "[*OS Disk Frag*]"
$JSON_DataDisk_Tag = "[*Disk Frag*]"
$JSON_Resource_Tag = "[*Resource Frag*]"
$JSON_OutFile = $ScriptFolder + "\JSON_OUT"
$RunTime_OutFile = $ScriptFolder + "\RunTime_OUT"

$JSON_Dep_Location = "Central US"
$JSON_Dep_Network = "MGENetwork"
$JSON_Dep_ResGrp = "MGENetworking"

$LookupColumn = "source"
$LookupReturn = "destination"
$LookupSrc = Import-Csv -Path ($ScriptFolder + "\conversions.csv")
#(get-ref -Src $LookupSrc -SrcColumn $LookupColumn -RetColumn $LookupReturn -key )
#EndRegion

Write-Host "`n`nAcessing subscription $((Get-AzureSubscription -Default).SubscriptionName)"
Write-Host "Collecting cloud service(s)..." -NoNewline 
#Grab all the Cloud services
$Services = Get-AzureService
Write-Host " Complete" -ForegroundColor Yellow -NoNewline

Write-Host "  Found $($Services.count) service(s)"

foreach($Service in $Services)
{
   $VMs = Get-AzureVM -Service $Service.ServiceName
   $JSON_Cloud = $null
   $First_VM = $true
   $Frag_OutFile = ($RunTime_OutFile + "\JSON_Frag_$($Service.ServiceName).json")
   $Resouce_OutFile = ($JSON_OutFile + "\JSON_$($Service.ServiceName).json")
   
   Write-Host "`nProcessing... $($VMs.count) VM(s)" 
   foreach($VM in $VMs)
   {
      if(!$First_VM){$JSON_Cloud[$JSON_Cloud.Length-1] = $JSON_Cloud[$JSON_Cloud.Length-1].replace("}","},")}
      $First_VM=$false
      Write-Host "   $($VM.Name)..." -NoNewline
      $Return = Get-AzureVMInformationForVM -VM $VM -outputFolderPath $RunTime_OutFile
      $Config = [XML](Get-Content $Return)
      
      ## Reset the Fragments
      $JSON = $JSON_VM_Fragment
      $JSON_OSDisk = $JSON_OSDisk_Fragment
      
      ## Update JSON with Derived values
      $JSON = $JSON.Replace("[*vmName*]",$Config.PersistentVM.RoleName)
      $JSON = $JSON.Replace("[*vmSize*]",(Get-ASRVMSize -ASMVMSize $Config.PersistentVM.RoleSize))
 
      ## OSDisk
      $JSON_OSDisk = $JSON_OSDisk.Replace("[*OSDiskName*]",$Config.PersistentVM.OSVirtualHardDisk.DiskName)
      $DiskStorage = (get-ref -Src $LookupSrc -SrcColumn $LookupColumn -RetColumn $LookupReturn -key ("osstore$($VM.Name)"))
      $JSON_OSDisk = $JSON_OSDisk.Replace("[*OSStorageAccountName*]",$DiskStorage)
      $JSON_OSDisk = $JSON_OSDisk.Replace("[*vmName*]",$Config.PersistentVM.RoleName)
      
      $JSON = (Insert-Fragment -Src_Frag $JSON -Frag_Key $JSON_OSDisk_Tag -Frag_Content $JSON_OSDisk)
      
      ## Network Information
      $SubNet = $Config.PersistentVM.ConfigurationSets.ConfigurationSet.SubnetNames.string
      $Network = $vm.VirtualNetworkName
      $NetKey = $Network.trim() + $SubNet.trim() 
      $SubNetRef = (get-ref -Src $LookupSrc -SrcColumn $LookupColumn -RetColumn $LookupReturn -key $NetKey)
      $JSON = $JSON.Replace("[*subnetName*]",$SubNetRef)
      
      ## Check for Data disk
      $JSON_Disks = ""
      if($AttachData)
      {
         [int]$DataDiskCt = $Config.PersistentVM.DataVirtualHardDisks.ChildNodes.Count
         if($DataDiskCt -gt 0)
         {
            $DataDisks = $Config.PersistentVM.DataVirtualHardDisks
            $JSON_Disks = $Null
            foreach($DataDisk in $DataDisks)
            {
               $JSON_Disk_Frag = $JSON_DataDisk_Fragment
               $JSON_Disk_Frag = $JSON_Disk_Frag.Replace("[*dataDiskName*]",$DataDisk.DataVirtualHardDisk.DiskName)
               $JSON_Disk_Frag = $JSON_Disk_Frag.Replace("[*dataDiskSize*]",$DataDisk.DataVirtualHardDisk.LogicalDiskSizeInGB)
               $JSON_Disk_Frag = $JSON_Disk_Frag.Replace("[*lunNumber*]",$DataDisk.DataVirtualHardDisk.Lun)
               $JSON_Disks += $JSON_Disk_Frag   
            }
         }
         
         ## Replace JSON values with values
         $DiskStorage = (get-ref -Src $LookupSrc -SrcColumn $LookupColumn -RetColumn $LookupReturn -key ("datastore$($VM.Name)"))
         $JSON_Disks = $JSON_Disks.Replace("[*DataStorageAccountName*]",$DiskStorage)
      }
      $JSON = (Insert-Fragment -Src_Frag $JSON -Frag_Key $JSON_DataDisk_Tag -Frag_Content $JSON_Disks)
      
      ##Save the JSON file 
      $JSON_Cloud += $JSON
      Write-Host -ForegroundColor Yellow " Complete" 
   }
   Write-Host -ForegroundColor Yellow "Processing of $($VMs.count) VM(s) complete`n" 

   #Strip off the extra ","
   Write-Host "Writing CS JSON fragment..." 
   Write-Host "   $($Frag_OutFile)" -NoNewline
   $JSON_Cloud[$JSON_Cloud.Length-1] = $JSON_Cloud[$JSON_Cloud.Length-1].replace("},","}")
   $JSON_Cloud | Out-File -FilePath $Frag_OutFile -Encoding string
   Write-Host -ForegroundColor Yellow " ...Complete" 
   
   Write-Host "Writing CS resource file..."  
   $JSON_Resource = $null ; $JSON_Resource = Get-Content ($ScriptFolder + "\JSON_Fragments\" + "Resource_Fragment.json")

   $JSON_Resource = $JSON_Resource.Replace("[*Location*]",$JSON_Dep_Location)
   $JSON_Resource = $JSON_Resource.Replace("[*DepNetwork*]",$JSON_Dep_Network)
   $JSON_Resource = $JSON_Resource.Replace("[*DepResGrp*]",$JSON_Dep_ResGrp)
   
   Write-Host "   <$($JSON_Resource_Tag)>$($Frag_OutFile)" -NoNewline 
   $xx = (Insert-Fragment -Src_Frag $JSON_Resource -Frag_Key $JSON_Resource_Tag -Frag_Content (Get-Content ($Frag_OutFile)) -Status $true)
   $xx | Out-File -FilePath $Resouce_OutFile -Encoding string

   Write-Host -ForegroundColor Yellow " ...Complete"
   
}

##End Script