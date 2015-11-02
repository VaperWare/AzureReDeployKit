#Region Functions

function local:Get-AzureVMInformationForVM
{
   param
   (
      [Parameter(Mandatory=$true)]$VM,
      [Parameter(Mandatory=$true)][string]$outputFolderPath
   )

   [string]$outPath = $outputFolderPath + '\' + $VM.Name + '.xml'
   $VM | Export-AzureVM -Path $outPath | Out-Null
return ($outPath)
}

function local:Get-ASRVMSize 
{
   param
   (
   [parameter(Mandatory=$true)][string]$ASMVMSize
   )
   $ASRVMSize = $ASMVMSize
   switch ($ASMVMSize) 
   {
   "ExtraSmall" { $ASRVMSize = "Standard_A0" }
   "Small" { $ASRVMSize = "Standard_A1" }
   "Medium" { $ASRVMSize = "Standard_A2" }
   "Large" { $ASRVMSize = "Standard_A3" }
   "ExtraLarge" { $ASRVMSize = "Standard_A4" }
   default {$ASRVMSize = "Standard_" + $ASRVMSize}
   }
   return ($ASRVMSize)
}

function local:Insert-Fragment
{
   param
   (
      [parameter(Mandatory=$true)]$Src_Frag,
      [parameter(Mandatory=$true)]$Frag_Key,
      [parameter(Mandatory=$true)]$Frag_Content,
      [parameter(Mandatory=$false)]$Status=$false
   )
   if($Src_Frag.IndexOf($Frag_Key) -ne -1)
   {
      if($Status){Write-Host " <Insert point found>" -ForegroundColor Green -NoNewline}
      $Src_Frag[$Src_Frag.IndexOf($Frag_Key)] = $Frag_Content
   } 
   else { 
      if($Status)
      {
         Write-Host " <Insert point NOT found>" -ForegroundColor Red -NoNewline 
         Write-Host ; Write-Host $Src_Frag -ForegroundColor White ; Write-Host "`n" ; Read-Host
      }
   }
   Return $Src_Frag
}

function local:get-ref
{
   param
   (
      [parameter(Mandatory=$true)]$Src,
      [parameter(Mandatory=$true)]$SrcColumn,
      [parameter(Mandatory=$true)]$Key,
      [parameter(Mandatory=$true)]$RetColumn
   )
 
   [int]$index = $Src.$SrcColumn.IndexOf($Key)
   if($index -ne -1)
   {
      $Return = $Src[$index].$RetColumn
   }

   return $Return
}

#EndRegion
