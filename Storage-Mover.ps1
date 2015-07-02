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
Param(
    [parameter(Mandatory=$false)][string]$SourceCloudService = "",
    [parameter(Mandatory=$false)][string]$DestCloudService = "",
	[parameter(Mandatory=$false)][string]$VMName = "",
	[parameter(Mandatory=$false)][string]$DestStorageAcct = "",
    [parameter(Mandatory=$false)][string]$DestStorageAcctKey = ""
)

#Copy VM from subscription to subscription
#http://blogs.msdn.com/b/microsoft_press/archive/2014/01/29/from-the-mvps-copying-a-virtual-machine-from-one-windows-azure-subscription-to-another-with-powershell.aspx
function local:Migrate-AzureVMs
{
    param ([parameter(Mandatory=$true)][string]$SourceCloudService = "",
    [parameter(Mandatory=$true)][string]$DestCloudService = "",
	[parameter(Mandatory=$false)][string]$VMName = "",
	[parameter(Mandatory=$true)][string]$DestStorageAcct = "",
    [parameter(Mandatory=$true)][string]$DestStorageAcctKey = "")

    # Check if Export directory exists
    if ((Test-Path -path ((Get-Location).Path + "\Export\")) -ne $True){
        Write-Host "Path to VM export doesn't exist...  Ensure a 'Export' folder exists before executing this script...  Exiting Script."
        Exit
    }

    # Do we want to get a specific VM or by cloud service
	if($SourceCloudService -ne $null -and $VMName -ne $null){
		$VMs = Get-AzureVM -ServiceName $SourceCloudService -Name $VMName -ErrorAction SilentlyContinue
	}else{
		$VMs = Get-AzureVM -ServiceName $SourceCloudService -ErrorAction SilentlyContinue
	}

    # Do VMs exist in that cloud service?  If not, we are done! :)
    if($VMs -eq $null){
        Write-Host "No VMs to migrate...  Exiting Script."
        Exit
    }

    # Get the current Azure Subscription
    $AzureSubscription = Get-AzureSubscription

    # Verify we have access to the destination storage account
    $destStorage = Get-AzureStorageAccount -StorageAccountName $DestStorageAcct
    $destContext = New-AzureStorageContext –StorageAccountName $DestStorageAcct -StorageAccountKey $DestStorageAcctKey -ErrorAction SilentlyContinue
    if ((Get-AzureStorageContainer -Context $destContext -Name vhds -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Host "Error connecting to the storage account..."
        Exit
    }

    # Iterate through all the VM(s) in the cloud service
	foreach($VM in $VMs){
        # XML File that will be used to storage the VM info
        $VMConfigPath = ((Get-Location).Path + "\Export\"+$VM.Name+".xml")

        # Export the current config as a backup
		Export-AzureVM -ServiceName $VM.ServiceName -Name $VM.Name -Path $VMConfigPath

        # Shutdown the VM
        Write-Host "Waiting for VM to shutdown..."
        Stop-AzureVM -ServiceName $VM.ServiceName -VM $VM.VM -Force

        # Get the source storage account we are working with
        $sourceStorageAccount = $VM.VM.OSVirtualHardDisk.MediaLink.Host.split(".")[0]

        # Get storage account key
        $StorageKey = Get-AzureStorageKey -StorageAccountName $sourceStorageAccount

        # Create a context to the source storage
        $sourceContext = New-AzureStorageContext –StorageAccountName $sourceStorageAccount -StorageAccountKey $StorageKey.Primary

        # Migrate to new storage
        $allDisks = @($VM.VM.OSVirtualHardDisk) + $VM.VM.DataVirtualHardDisks
        $destDataDisks = @()
        foreach($disk in $allDisks)
        {
            $blobName = $disk.MediaLink.Segments[2]
            $targetBlob = Start-CopyAzureStorageBlob -SrcContainer vhds -SrcBlob $blobName -DestContainer vhds -DestBlob $blobName `
                                                        -Context $sourceContext -DestContext $destContext -Force
            Write-Host "Copying blob $blobName"

            # Log the status of the file transfer from one account to the other
            $BlobCopyState = $targetBlob | Get-AzureStorageBlobCopyState
            while ($BlobCopyState.Status -ne "Success")
            {
                $percent = ($BlobCopyState.BytesCopied / $BlobCopyState.TotalBytes) * 100
                Write-Host "Completed $('{0:N2}' -f $percent)%"
                Start-Sleep -Seconds 5
                $BlobCopyState = $targetBlob | Get-AzureStorageBlobCopyState
            }

            # Create variable of each disk for remapping
            if ($disk –eq $VM.VM.OSVirtualHardDisk )
            {
                $destOSDisk = $targetBlob
            }
            else
            {
                $destDataDisks += $targetBlob
            }
        }

        # Delete Azure source VM
        Remove-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName
        # Remove Azure Disk from the Azure disk repository in the current subscription
        Remove-AzureDisk -DiskName $VM.VM.OSVirtualHardDisk.DiskName

        # Add copied OS disk to the Microsoft Azure disk repository
        Add-AzureDisk -OS $VM.VM.OSVirtualHardDisk.OS -DiskName $VM.VM.OSVirtualHardDisk.DiskName -MediaLocation $destOSDisk.ICloudBlob.Uri.OriginalString
        foreach($currenDataDisk in $destDataDisks)
        {
            $diskName = ($VM.VM.DataVirtualHardDisks | ? {$_.MediaLink.Segments[2] -eq $currenDataDisk.Name}).DiskName
            # Remove Azure Disk from the Azure disk repository in the current subscription
            Remove-AzureDisk -DiskName $diskName

            # Add copied disk to the Microsoft Azure disk repository
            Add-AzureDisk -DiskName $diskName -MediaLocation $currenDataDisk.ICloudBlob.Uri
        }

        # Redeploy the VM
        $AzureVMImport = Import-AzureVM -Path $VMConfigPath
        $NewVMParams = @{
                        ServiceName = $DestCloudService
                        Location =  $destStorage.Location
                        VMs = $AzureVMImport
                        }

        if($VM.VirtualNetworkName -ne $null){
            $NewVMParams+= @{VNET = $VM.VirtualNetworkName}
        }


        # Set the storage context
        Set-AzureSubscription -SubscriptionName $AzureSubscription.SubscriptionName -CurrentStorageAccountName $destContext.StorageAccountName -PassThru

        # Provision the VM
        New-AzureVM @NewVMParams -WaitForBoot
    }

    Write-Output ($ArrayofVMs | ConvertTo-XML -notypeinformation).InnerXml
}

#EndRegion

#Examples
# test variables
$SourceCloudService = "JackTestVM002"
$DestCloudService   = "RightNow"
$DestStorageAcct    = "eaststoragetest001"
$DestStorageAcctKey = "JczYofh/B/Bh1Y5ug/ofGB94N6bb467oEu+TstdTA2Ly1kf1DMsLBCVTmT5os1RmjNd/SIWEjbeRyk2dtx/Rbg=="
Migrate-AzureVMs -SourceCloudService $SourceCloudService -DestCloudService $DestCloudService -DestStorageAcct $DestStorageAcct -DestStorageAcctKey $DestStorageAcctKey

## End Script