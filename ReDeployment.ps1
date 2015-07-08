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
    [parameter(Mandatory=$false)][string]$ScriptFolder = (get-location).Path,
    [parameter(Mandatory=$false)][string]$SubConfigFile = (Join-Path -Path (get-location).Path -ChildPath 'Sub_config.xml')
    
)

##Start overall stop watch
$StopWatch = New-Object System.Diagnostics.Stopwatch;$StopWatch.Start()

##define Const's
set-variable -name SharedFunctions -value "SharedComponents\VMRedeployFunctions.psm1" -option constant -Visibility Public
set-variable -name Module -value (Join-Path -Path $scriptFolder -ChildPath $SharedFunctions) -option constant -Visibility Public

##Load the functions
if (!(test-path -Path $Module)){Write-Host "File $($Module) is missing.. Aborting";exit}
Import-Module $Module -AsCustomObject -Force -DisableNameChecking -Verbose:$false -ErrorAction Stop

$config = [xml](gc $SubConfigFile -ErrorAction Stop)
##Select-AzureSubscription -SubscriptionName $config.Azure.SubscriptionName -errorAction Stop

#Write-Host -ForegroundColor Green "using subscription: <$((Get-AzureSubscription -Current).SubscriptionName)>"

$CloudServices = $config.Azure.CloudServices
Write-Host -ForegroundColor Red "<$($CloudServices)>"
foreach ($CloudService in $CloudServices.cloudservice){
   $Servers = $CloudService.Servers
   foreach ($Server in $Servers.AzureVM){
      Write-Host $server.Name
   }
}


$StopWatch.Stop();$ts = $StopWatch.Elapsed
write-host ("`nRe-Deployment completed in {0} hours {1} minutes, {2} seconds`n" -f $ts.Hours, $ts.Minutes, $ts.Seconds)
################## Script execution end ##############
