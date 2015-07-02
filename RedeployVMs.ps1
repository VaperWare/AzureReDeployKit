#Requirements
#1.	PowerShell script to re-deploy a VM
#a.	Input parameters
#i.	Cloud service name
#ii.	VM Name
#iii.	Destination subnet
#b.	Save/capture information
#i.	OS Disk 
#ii.	Data disk(s)
#iii.	Endpoint(s)
#c.	Delete the VM (keep OS Disk)
#d.	Re-build VM to new Subnet using save/captured information
param(
	[Parameter(Mandatory=$true)]
	[string]$ServiceName,
	[Parameter(Mandatory=$true)]
	[string]$VNetName,
	[Parameter(Mandatory=$true)]
	[string]$VMName,
	[Parameter(Mandatory=$true)]
	[string]$StorageAccountName
)

# Set path to shared functions
 $scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
##Load the functions
 Import-Module $scriptFolder\SharedComponents\VMRedeployFunctions.psm1 -AsCustomObject -Force -DisableNameChecking -Verbose:$false

Add-AzureAccount

$subscription = Get-AzureSubscription -Current   
Write-Host "using subscription: " $subscription.SubscriptionName

[string]$VMFile = Get-MCAzureVMInformationForVM -ServiceName $ServiceName -VMName $VMName
$VMFiles = $VMFile.Split(" ")
$filePath = $VMFiles[1]
Write-Host "$($filePath)"

pauseforkeypress

#delete VM while keeping the disks
Remove-AzureVM -ServiceName $ServiceName -Name $VMName

#Insert code to move VM Hard Drive

Write-Host "Please use this time to edit your file located at " + $VMFile + " and edit the necessary information (IE Subnet, etc...).  Ensure the subnet in the file exists on the VNet. Once you have that completed, hit any key to continue..."

pauseforkeypress

Write-Host "Re-importing $($VMName) from file $($VMFile) in storage account $($StorageAccountName) to VNET $($VNetName) waiting 2 min..."

Wait -InSeconds 120
#Re-import VM to correct VNET
New-MCAzureVMOnVNetFromInformationFile -ServiceName $ServiceName -Path $filePath -VNetName $VNetName -StorageAccountName $StorageAccountName

