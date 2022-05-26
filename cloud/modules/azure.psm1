<#
.SYNOPSIS
    OSDCloud Cloud Module for functions.osdcloud.com
.DESCRIPTION
    OSDCloud Cloud Module for functions.osdcloud.com
.NOTES
    This module can be loaded in all Windows phases
.LINK
    https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/azure.psm1
.EXAMPLE
    Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/azure.psm1')
#>
#=================================================
#region Functions
function Connect-AzOSDCloud {
    [CmdletBinding()]
    param (
        [System.Management.Automation.SwitchParameter]
        $UseDeviceAuthentication
    )
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Green "Connect-AzOSDCloud"

    if ($env:SystemDrive -eq 'X:') {
        $UseDeviceAuthentication = $true
        $DebugLogs = "$env:SystemDrive\DebugLogs"
        if (-not (Test-Path $DebugLogs)) {
            New-Item $DebugLogs -ItemType Directory -Force | Out-Null
        }
    }

    osdcloud-InstallModuleAzureAD
    osdcloud-InstallModuleAzAccounts
        #Connect-AzAccount
        #Get-AzSubscription
        #Set-AzContext
        #Get-AzContext
        #Get-AzAccessToken
    osdcloud-InstallModuleAzKeyVault
    osdcloud-InstallModuleAzResources
    osdcloud-InstallModuleAzStorage
    osdcloud-InstallModuleMSGraphAuthentication
    osdcloud-InstallModuleMSGraphDeviceManagement

    if ($UseDeviceAuthentication) {
        Connect-AzAccount -UseDeviceAuthentication -AuthScope Storage -ErrorAction Stop
    }
    else {
        Connect-AzAccount -AuthScope Storage -ErrorAction Stop
    }

    $Global:AzSubscription = Get-AzSubscription
    if ($DebugLogs) {
        $Global:AzSubscription | ConvertTo-Json | Out-File -FilePath "$DebugLogs\AzSubscription.json" -Encoding ascii -Width 2000 -Force
    }

    if (($Global:AzSubscription).Count -ge 2) {
        $i = $null
        $Results = foreach ($Item in $Global:AzSubscription) {
            $i++
    
            $ObjectProperties = @{
                Number  = $i
                Name    = $Item.Name
                Id      = $Item.Id
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    
        $Results | Select-Object -Property Number, Name, Id | Format-Table | Out-Host
    
        do {
            $SelectReadHost = Read-Host -Prompt "Select an Azure Subscription by Number"
        }
        until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Results.Number))))
    
        $Results = $Results | Where-Object {$_.Number -eq $SelectReadHost}
    
        $Global:AzContext = Set-AzContext -Subscription $Results.Id
    }
    else {
        $Global:AzContext = Get-AzContext
    }

    if ($Global:AzContext) {
        if ($DebugLogs) {
            $Global:AzContext | ConvertTo-Json | Out-File -FilePath "$DebugLogs\AzContext.json" -Encoding ascii -Width 2000 -Force
        }
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Green 'Welcome to Azure OSDCloud!'
        $Global:AzAccount = $Global:AzContext.Account
        $Global:AzEnvironment = $Global:AzContext.Environment
        $Global:AzTenantId = $Global:AzContext.Tenant
        $Global:AzSubscription = $Global:AzContext.Subscription

        Write-Host -ForegroundColor Cyan        '$Global:AzAccount:        ' $Global:AzAccount
        Write-Host -ForegroundColor Cyan        '$Global:AzEnvironment:    ' $Global:AzEnvironment
        Write-Host -ForegroundColor Cyan        '$Global:AzTenantId:       ' $Global:AzTenantId
        Write-Host -ForegroundColor Cyan        '$Global:AzSubscription:   ' $Global:AzSubscription
        if ($null -eq $Global:AzContext.Subscription) {
            Write-Warning 'You do not have access to an Azure Subscriptions'
            Write-Warning 'This is likely due to not having rights to Azure Resources or Azure Storage'
            Write-Warning 'Contact your Azure administrator to resolve this issue'
            Break
        }

        Write-Host ''
        Write-Host -ForegroundColor DarkGray    'Azure Context:             $Global:AzContext'
        Write-Host -ForegroundColor DarkGray    'Access Tokens:             $Global:Az*AccessToken'
        Write-Host -ForegroundColor DarkGray    'Headers:                   $Global:Az*Headers'
        Write-Host ''
        #=================================================
        #	AAD Graph
        #=================================================
        $Global:AzAadGraphAccessToken = Get-AzAccessToken -ResourceTypeName AadGraph
        $Global:AzAadGraphHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzAadGraphAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzAadGraphAccessToken.ExpiresOn
        }
        #=================================================
        #	Azure KeyVault
        #=================================================
        $Global:AzKeyVaultAccessToken = Get-AzAccessToken -ResourceTypeName KeyVault
        $Global:AzKeyVaultHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzKeyVaultAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzKeyVaultAccessToken.ExpiresOn
        }
        #=================================================
        #	Azure MSGraph
        #=================================================
        $Global:AzMSGraphAccessToken = Get-AzAccessToken -ResourceTypeName MSGraph
        $Global:AzMSGraphHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzMSGraphAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzMSGraphHeaders.ExpiresOn
        }
        #=================================================
        #	Azure Storage
        #=================================================
        $Global:AzStorageAccessToken = Get-AzAccessToken -ResourceTypeName Storage
        $Global:AzStorageHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzStorageAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzStorageHeaders.ExpiresOn
        }
        #=================================================
        #	AzureAD
        #=================================================
        #$Global:MgGraph = Connect-MgGraph -AccessToken $Global:AzMSGraphAccessToken.Token -Scopes DeviceManagementConfiguration.Read.All,DeviceManagementServiceConfig.Read.All,DeviceManagementServiceConfiguration.Read.All
        $Global:AzureAD = Connect-AzureAD -AadAccessToken $Global:AzAadGraphAccessToken.Token -AccountId $Global:AzContext.Account.Id
        if ($DebugLogs) {
            #$Global:AzureAD | ConvertTo-Json | Out-File -FilePath "$DebugLogs\AzureAD.json" -Encoding ascii -Width 2000 -Force
        }
    }
    else {
        Write-Warning 'Unable to get AzContext'
    }
}
New-Alias -Name 'Connect-AzWinPE' -Value 'Connect-AzOSDCloud' -Description 'OSDCloud' -Force
New-Alias -Name 'Connect-AzureWinPE' -Value 'Connect-AzOSDCloud' -Description 'OSDCloud' -Force
#endregion
#=================================================