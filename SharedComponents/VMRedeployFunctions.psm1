function Get-MCAzureVMInformationForService
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Cloud Service Name of Cloud Service to get VMs Information for.')
		][string[]]$ServiceName,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)][string]$outputFolderPath=$PWD.Path)
		
	foreach($vm in Get-AzureVM -ServiceName $cloudServiceName)
	{
		$outPath = $outputFolderPath + '\' + $vm.Name + '.xml'
		Export-AzureVM -ServiceName $ServiceName -Name $vm.Name -Path $outPath
	}
}
function local:Get-MCAzureVMInformationForVM
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Cloud Service Name of Cloud Service to get VMs Information for.')
		][string]$ServiceName,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)][string]$outputFolderPath=$PWD.Path,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='VM Name of VM to get Information for')]
		[string]$VMName
		)
		[string]$outPath = $outputFolderPath + '\' + $VMName + '.xml'
		Export-AzureVM -ServiceName $ServiceName -Name $VMName -Path $outPath
		#Write-Host (Test-Path -Path $outPath)
		#$outPath | GM | OGV 
		#pauseforkeypress
		return ($outputFolderPath + '\' + $VMName + '.xml')
}
function pauseforkeypress
{
	
	param(
		[string]$Message = ""
		)
	Write-Host "$($Message) Hit Any Key to Continue..."
	$HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
	$HOST.UI.RawUI.Flushinputbuffer()

}
function New-MCAzureVMMassDeploymentFromInformationFolder
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Path of folder containing .xml files to be imported')]
		[string]$Path,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of deployment VNet')]
		[string]$VNetName,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of Cloud Service for deployment')]
		[string]$ServiceName,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of Storage Account where XML File is stored')]
		[string]$StorageAccountName
	)
	$vms = @()
	Get-ChildItem $Path | foreach {
		if($_ -contains ".xml")
		{
			$path = $Path + $_
			$vms += Import-AzureVM -Path $Path
		}
	}
	$subscription = Get-AzureSubscription -Current
	Set-AzureSubscription -SubscriptionName $subscription.SubscriptionName -CurrentStorageAccount $StorageAccountName
	New-AzureVM -ServiceName $ServiceName -VMs $vms -VNet $VNetName
}
function New-MCAzureVMOnVNetFromInformationFile
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Path of to .xml file to be imported including extension')]
		[string]$Path,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of deployment VNet')]
		[string]$VNetName,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of Cloud Service for deployment')]
		[string]$ServiceName,
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage='Name of Storage Account where XML File is stored')]
		[string]$StorageAccountName
	)
	$subscription = Get-AzureSubscription -Current
	Set-AzureSubscription -SubscriptionName $subscription.SubscriptionName -CurrentStorageAccount $StorageAccountName
	Write-Host "$($Path) exists: "
	
	Import-AzureVM -Path $Path | New-AzureVM -ServiceName $ServiceName -VNet $VNetName
}
Function local:Wait ()
{
param([string]$msg="Pausing",[int]$InSeconds=60)
   $Sleep = $InSeconds ; $delay = 1

    if ($inSeconds -ge 60) {
      [int]$delay = $InSeconds / 60 ; $Sleep = 60
    }
    elseif ($inSeconds -lt 60){
      [int]$delay = 1 ; $Sleep = $InSeconds
    }
    else {
      [int]$delay = 1 ; $Sleep = $InSeconds
    }
    
    [int]$Count = 0 ; Write-Host "$($msg) ($($InSeconds.ToString().Trim()) seconds)" -NoNewline
    while ($Count -lt $delay){write-host -NoNewline "."; sleep $Sleep;$count += 1};Write-Host ".. Resuming"
}

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





