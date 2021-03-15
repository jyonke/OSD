<#
.SYNOPSIS
Starts the OSDCloud Windows 10 Build Process from the OSD Module or a GitHub Repository

.DESCRIPTION
Starts the OSDCloud Windows 10 Build Process from the OSD Module or a GitHub Repository

.PARAMETER OSEdition
Edition of the Windows installation

.PARAMETER OSCulture
Culture of the Windows installation

.PARAMETER Screenshot
Captures screenshots during OSDCloud

.PARAMETER GitHub
Starts OSDCloud from GitHub
GitHub Variable Url: $GitHubBaseUrl/$GitHubUser/$GitHubRepository/$GitHubBranch/$GitHubScript
GitHub Resolved Url: https://raw.githubusercontent.com/OSDeploy/OSDCloud/main/Start-OSDCloud.ps1

.PARAMETER GitHubBaseUrl
The GitHub Base URL

.PARAMETER GitHubUser
GitHub Repository User

.PARAMETER GitHubRepository
OSDCloud Repository

.PARAMETER GitHubBranch
Branch of the Repository

.PARAMETER GitHubScript
Script to execute

.PARAMETER GitHubToken
Used to access a GitHub Private Repository

.LINK
https://osdcloud.osdeploy.com/

.NOTES
21.3.12 Module vs GitHub options added
21.3.10 Added additional parameters
21.3.9  Initial Release
#>
function Start-OSDCloud {
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param (
        [ValidateSet('2009','2004','1909','1903','1809')]
        [Alias('Build')]
        [string]$OSBuild = '2009',

        [ValidateSet('Education','Enterprise','Pro')]
        [Alias('Edition')]
        [string]$OSEdition = 'Enterprise',

        [ValidateSet (
            'ar-sa','bg-bg','cs-cz','da-dk','de-de','el-gr',
            'en-gb','en-us','es-es','es-mx','et-ee','fi-fi',
            'fr-ca','fr-fr','he-il','hr-hr','hu-hu','it-it',
            'ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl',
            'pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk',
            'sl-si','sr-latn-rs','sv-se','th-th','tr-tr',
            'uk-ua','zh-cn','zh-tw'
        )]
        [Alias('Culture')]
        [string]$OSCulture = 'en-us',

        [switch]$Screenshot,

        [Parameter(ParameterSetName = 'GitHub')]
        [switch]$GitHub,

        [Parameter(ParameterSetName = 'GitHub')]
        [string]$GitHubBaseUrl = 'https://raw.githubusercontent.com',
        
        [Parameter(ParameterSetName = 'GitHub')]
        [Alias('U','User')]
        [string]$GitHubUser = 'OSDeploy',

        [Parameter(ParameterSetName = 'GitHub')]
        [Alias('R','Repository')]
        [string]$GitHubRepository = 'OSDCloud',

        [Parameter(ParameterSetName = 'GitHub')]
        [Alias('B','Branch')]
        [string]$GitHubBranch = 'main',

        [Parameter(ParameterSetName = 'GitHub')]
        [Alias('S','Script')]
        [string]$GitHubScript = 'Start-OSDCloud.ps1',

        [Parameter(ParameterSetName = 'GitHub')]
        [Alias('T','Token')]
        [string]$GitHubToken = ''
    )

    $Global:OSDCloudStartTime = Get-Date
    #===================================================================================================
    #	About Save
    #===================================================================================================
    if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
        $GetUSBVolume = Get-USBVolume | Where-Object {$_.FileSystem -eq 'NTFS'} | Where-Object {$_.SizeGB -ge 8} | Sort-Object DriveLetter -Descending

        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Save-OSDCloud will save all required content to an 8GB+ NTFS USB Volume"
        Write-Host -ForegroundColor White "Windows 10 will require about 4GB"
        Write-Host -ForegroundColor White "Hardware Drivers will require between 1-2GB for Dell Systems"

        if (-NOT ($GetUSBVolume)) {
            Write-Warning "Unfortunately, I don't see any USB Volumes that will work"
            Write-Warning "Save-OSDCloud has left the building"
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Break
        }

        Write-Warning "USB Free Space is not verified before downloading yet, so this is on you!"
        Write-Host -ForegroundColor DarkGray "========================================================================="
    }
    #===================================================================================================
    #	Get-USBVolume
    #===================================================================================================
    if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
        if (Get-USBVolume) {
            #$GetUSBVolume | Select-Object -Property DriveLetter, FileSystemLabel, SizeGB, SizeRemainingMB, DriveType | Format-Table
            $SelectUSBVolume = Select-USBVolume -MinimumSizeGB 8 -FileSystem 'NTFS'
            $OSDCloudOffline = "$($SelectUSBVolume.DriveLetter):\OSDCloud"
            Write-Host -ForegroundColor White "OSDCloud content will be saved to $OSDCloudOffline"
        } else {
            Write-Warning "Save-OSDCloud USB Requirements:"
            Write-Warning "8 GB Minimum"
            Write-Warning "NTFS File System"
            Break
        }
    }
    #===================================================================================================
    #   Screenshots
    #===================================================================================================
    if ($PSBoundParameters.ContainsKey('Screenshots')) {
        Start-ScreenPNGProcess -Directory "$env:TEMP\ScreenPNG"
    }
    #===================================================================================================
    #	Global Variables
    #===================================================================================================
    $Global:OSEdition = $OSEdition
    $Global:OSCulture = $OSCulture
    #===================================================================================================
    #	AutoPilot Profiles
    #===================================================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "AutoPilot Profiles"
    if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
        if (-NOT (Test-Path "$OSDCloudOffline\AutoPilot\Profiles")) {
            New-Item -Path "$OSDCloudOffline\AutoPilot\Profiles" -ItemType Directory -Force | Out-Null
        }
    }

    $GetOSDCloudAutoPilotProfiles = Get-OSDCloudAutoPilotProfiles

    if ($GetOSDCloudAutoPilotProfiles) {
        foreach ($Item in $GetOSDCloudAutoPilotProfiles) {
            Write-Host -ForegroundColor Yellow "$($Item.FullName)"
        }
    } else {
        Write-Warning "No AutoPilot Profiles were found in any PSDrive"
        Write-Warning "AutoPilot Profiles must be located in a <PSDrive>:\OSDCloud\AutoPilot\Profiles direcory"
    }
    #===================================================================================================
    #	PSGallery Modules
    #===================================================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "PowerShell Modules and Scripts"
    if (Test-WebConnection -Uri "https://www.powershellgallery.com") {
        if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
            if (-NOT (Test-Path "$OSDCloudOffline\PowerShell\Modules")) {
                New-Item -Path "$OSDCloudOffline\PowerShell\Modules" -ItemType Directory -Force | Out-Null
            }
            Write-Host -ForegroundColor DarkGray "Save-Module OSD"
            Save-Module -Name OSD -Path "$OSDCloudOffline\PowerShell\Modules"

            Write-Host -ForegroundColor DarkGray "Save-Module WindowsAutoPilotIntune"
            Save-Module -Name WindowsAutoPilotIntune -Path "$OSDCloudOffline\PowerShell\Modules"
            Write-Host -ForegroundColor DarkGray "Save-Module AzureAD"
            Write-Host -ForegroundColor DarkGray "Save-Module Microsoft.Graph.Intune"

            if (-NOT (Test-Path "$OSDCloudOffline\PowerShell\Scripts")) {
                New-Item -Path "$OSDCloudOffline\PowerShell\Scripts" -ItemType Directory -Force | Out-Null
            }
            Write-Host -ForegroundColor DarkGray "Save-Script Get-WindowsAutoPilotInfo"
            Save-Script -Name Get-WindowsAutoPilotInfo -Path "$OSDCloudOffline\PowerShell\Scripts"
        }
    }
    else {
        Write-Warning "Could not verify an Internet connection to the PowerShell Gallery"
        if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
            Write-Warning "OSDCloud will continue, but there may be issues"
        }
        
        if ($MyInvocation.MyCommand.Name -eq 'Start-OSDCloud') {
            Write-Warning "OSDCloud will continue, but there may be issues"
        }
    }
    #===================================================================================================
    #	Windows 10
    #===================================================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "Windows 10 x64"
    Write-Host -ForegroundColor White "OSBuild: $OSBuild"
    Write-Host -ForegroundColor White "OSCulture: $OSCulture"
    
    $GetFeatureUpdate = Get-FeatureUpdate -OSBuild $OSBuild -OSCulture $OSCulture

    if ($GetFeatureUpdate) {
        $GetFeatureUpdate = $GetFeatureUpdate | Select-Object -Property CreationDate,KBNumber,Title,UpdateOS,UpdateBuild,UpdateArch,FileName, @{Name='SizeMB';Expression={[int]($_.Size /1024/1024)}},FileUri,Hash,AdditionalHash
    }
    else {
        Write-Warning "Unable to locate a Windows 10 Feature Update"
        Break
    }
    Write-Host -ForegroundColor White "CreationDate: $($GetFeatureUpdate.CreationDate)"
    Write-Host -ForegroundColor White "KBNumber: $($GetFeatureUpdate.KBNumber)"
    Write-Host -ForegroundColor White "Title: $($GetFeatureUpdate.Title)"
    Write-Host -ForegroundColor White "FileName: $($GetFeatureUpdate.FileName)"
    Write-Host -ForegroundColor White "SizeMB: $($GetFeatureUpdate.SizeMB)"
    Write-Host -ForegroundColor White "FileUri: $($GetFeatureUpdate.FileUri)"

    $GetOSDCloudOfflineFile = Get-OSDCloudOfflineFile -Name $GetFeatureUpdate.FileName | Select-Object -First 1

    if ($GetOSDCloudOfflineFile) {
        Write-Host -ForegroundColor Cyan "Offline: $($GetOSDCloudOfflineFile.FullName)"
    }
    elseif (Test-WebConnection -Uri $GetFeatureUpdate.FileUri) {
        if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
            Save-OSDDownload -SourceUrl $GetFeatureUpdate.FileUri -DownloadFolder "$OSDCloudOffline\OS" | Out-Null
            if (Test-Path $Global:OSDDownload.FullName) {
                Rename-Item -Path $Global:OSDDownload.FullName -NewName $GetFeatureUpdate.FileName -Force
            }
        }
    }
    else {
        Write-Warning "Could not verify an Internet connection for Windows 10 Feature Update"
        Write-Warning "OSDCloud cannot continue"
        Break
    }
    #===================================================================================================
    #	Dell Driver Pack
    #===================================================================================================
    if ((Get-MyComputerManufacturer -Brief) -eq 'Dell') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Dell Driver Pack"
        
        $GetMyDellDriverCab = Get-MyDellDriverCab
        if ($GetMyDellDriverCab) {
            Write-Host -ForegroundColor White "LastUpdate: $($GetMyDellDriverCab.LastUpdate)"
            Write-Host -ForegroundColor White "DriverName: $($GetMyDellDriverCab.DriverName)"
            Write-Host -ForegroundColor White "Generation: $($GetMyDellDriverCab.Generation)"
            Write-Host -ForegroundColor White "Model: $($GetMyDellDriverCab.Model)"
            Write-Host -ForegroundColor White "SystemSku: $($GetMyDellDriverCab.SystemSku)"
            Write-Host -ForegroundColor White "DriverVersion: $($GetMyDellDriverCab.DriverVersion)"
            Write-Host -ForegroundColor White "DriverReleaseId: $($GetMyDellDriverCab.DriverReleaseId)"
            Write-Host -ForegroundColor White "OsVersion: $($GetMyDellDriverCab.OsVersion)"
            Write-Host -ForegroundColor White "OsArch: $($GetMyDellDriverCab.OsArch)"
            Write-Host -ForegroundColor White "DownloadFile: $($GetMyDellDriverCab.DownloadFile)"
            Write-Host -ForegroundColor White "SizeMB: $($GetMyDellDriverCab.SizeMB)"
            Write-Host -ForegroundColor White "DriverUrl: $($GetMyDellDriverCab.DriverUrl)"
            Write-Host -ForegroundColor White "DriverInfo: $($GetMyDellDriverCab.DriverInfo)"

            $GetOSDCloudOfflineFile = Get-OSDCloudOfflineFile -Name $GetMyDellDriverCab.DownloadFile | Select-Object -First 1
        
            if ($GetOSDCloudOfflineFile) {
                Write-Host -ForegroundColor Cyan "Offline: $($GetOSDCloudOfflineFile.FullName)"
            }
            elseif (Test-MyDellDriverCabWebConnection) {
                if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
                    Save-OSDDownload -SourceUrl $GetMyDellDriverCab.DriverUrl -DownloadFolder "$OSDCloudOffline\DriverPacks" | Out-Null
                }
            }
            else {
                Write-Warning "Could not verify an Internet connection for the Dell Driver Pack"
                Write-Warning "OSDCloud will continue, but there may be issues"
            }
        }
        else {
            Write-Warning "Unable to determine a suitable Driver Pack for this Computer Model"
        }
    }
    #===================================================================================================
    #	Dell BIOS Update
    #===================================================================================================
    if ((Get-MyComputerManufacturer -Brief) -eq 'Dell') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Dell BIOS Update"

        $GetMyDellBios = Get-MyDellBios
        if ($GetMyDellBios) {
            Write-Host -ForegroundColor White "ReleaseDate: $($GetMyDellBios.ReleaseDate)"
            Write-Host -ForegroundColor White "Name: $($GetMyDellBios.Name)"
            Write-Host -ForegroundColor White "DellVersion: $($GetMyDellBios.DellVersion)"
            Write-Host -ForegroundColor White "Url: $($GetMyDellBios.Url)"
            Write-Host -ForegroundColor White "Criticality: $($GetMyDellBios.Criticality)"
            Write-Host -ForegroundColor White "FileName: $($GetMyDellBios.FileName)"
            Write-Host -ForegroundColor White "SizeMB: $($GetMyDellBios.SizeMB)"
            Write-Host -ForegroundColor White "PackageID: $($GetMyDellBios.PackageID)"
            Write-Host -ForegroundColor White "SupportedModel: $($GetMyDellBios.SupportedModel)"
            Write-Host -ForegroundColor White "SupportedSystemID: $($GetMyDellBios.SupportedSystemID)"
            Write-Host -ForegroundColor White "Flash64W: $($GetMyDellBios.Flash64W)"

            $GetOSDCloudOfflineFile = Get-OSDCloudOfflineFile -Name $GetMyDellBios.FileName | Select-Object -First 1
            if ($GetOSDCloudOfflineFile) {
                Write-Host -ForegroundColor Cyan "Offline: $($GetOSDCloudOfflineFile.FullName)"
            }
            else {
                Save-MyDellBios -DownloadPath "$OSDCloudOffline\BIOS"
            }

            $GetOSDCloudOfflineFile = Get-OSDCloudOfflineFile -Name 'Flash64W.exe' | Select-Object -First 1
            if ($GetOSDCloudOfflineFile) {
                Write-Host -ForegroundColor Cyan "Offline: $($GetOSDCloudOfflineFile.FullName)"
            }
            else {
                Save-MyDellBiosFlash64W -DownloadPath "$OSDCloudOffline\BIOS"
            }
        }
        else {
            Write-Warning "Unable to determine a suitable BIOS update for this Computer Model"
        }
    }
    #===================================================================================================
    #	Save-OSDCloud Complete
    #===================================================================================================
    if ($MyInvocation.MyCommand.Name -eq 'Save-OSDCloud') {
		$Global:OSDCloudEndTime = Get-Date
		$Global:OSDCloudTimeSpan = New-TimeSpan -Start $Global:OSDCloudStartTime -End $Global:OSDCloudEndTime
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Save-OSDCloud completed in $($Global:OSDCloudTimeSpan.ToString("mm' minutes 'ss' seconds'"))!"
        explorer $OSDCloudOffline
        Write-Host -ForegroundColor DarkGray "========================================================================="
    }
    #===================================================================================================


    #===================================================================================================
    #   Module
    #===================================================================================================
    if ($PSCmdlet.ParameterSetName -eq 'Module') {
        & "$($MyInvocation.MyCommand.Module.ModuleBase)\Deploy-OSDCloud.ps1"
    }
    #===================================================================================================
    #   GitHub
    #===================================================================================================
    if ($PSCmdlet.ParameterSetName -eq 'GitHub') {

        if (-NOT (Test-WebConnection $GitHubBaseUrl)) {
            Write-Warning "Could not verify an Internet connection to $Global:GitHubUrl"
            Write-Warning "OSDCloud -GitHub cannot continue"
            Write-Warning "Verify you have an Internet connection or remove the -GitHub parameter"
            Break
        }

        if ($PSBoundParameters['Token']) {
            $Global:GitHubUrl = "$GitHubBaseUrl/$GitHubUser/$GitHubRepository/$GitHubBranch/$GitHubScript`?token=$GitHubToken"
        } else {
            $Global:GitHubUrl = "$GitHubBaseUrl/$GitHubUser/$GitHubRepository/$GitHubBranch/$GitHubScript"
        }

        if (-NOT (Test-WebConnection $Global:GitHubUrl)) {
            Write-Warning "Could not verify an Internet connection to $Global:GitHubUrl"
            Write-Warning "OSDCloud -GitHub cannot continue"
            Write-Warning "Verify you have an Internet connection or remove the -GitHub parameter"
            Break
        }

        $Global:GitHubBaseUrl = $GitHubBaseUrl
        $Global:GitHubUser = $GitHubUser
        $Global:GitHubRepository = $GitHubRepository
        $Global:GitHubBranch = $GitHubBranch
        $Global:GitHubScript = $GitHubScript
        $Global:GitHubToken = $GitHubToken

        Invoke-WebPSScript -WebPSScript $Global:GitHubUrl
    }
    #===================================================================================================
}