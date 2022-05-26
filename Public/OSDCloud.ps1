function Invoke-OSDCloud {
    <#
    .SYNOPSIS
    This is the master OSDCloud Task Sequence
    
    .DESCRIPTION
    This is the master OSDCloud Task Sequence
    
    .LINK
    https://github.com/OSDeploy/OSD/tree/master/Docs
    #>
    [CmdletBinding()]
    param ()
    #=================================================
    #region Master Parameters
    #=================================================
    $Global:OSDCloud = $null
    $Global:OSDCloud = [ordered]@{
        ApplyManufacturerDrivers = $true
        ApplyCatalogDrivers = $true
        ApplyCatalogFirmware = $true
        AutopilotJsonChildItem = $null
        AutopilotJsonItem = $null
        AutopilotJsonName = $null
        AutopilotJsonObject = $null
        AutopilotJsonString = $null
        AutopilotJsonUrl = $null
        AutopilotOOBEJsonChildItem = $null
        AutopilotOOBEJsonItem = $null
        AutopilotOOBEJsonName = $null
        AutopilotOOBEJsonObject = $null
        AzContext = $Global:AzContext
        AzOSDCloudBlobImage = $Global:AzOSDCloudBlobImage
        AzOSDCloudBlobDriverPack = $Global:AzOSDCloudBlobDriverPack
        AzOSDCloudDriverPack = $null
        AzOSDCloudImage = $Global:AzOSDCloudImage
        AzStorageAccounts = $Global:AzStorageAccounts
        AzStorageContext = $Global:AzStorageContext
        BuildName = 'OSDCloud'
        DriverPack = $null
        DriverPackBaseName = $null
        DriverPackExpand = [bool]$false
        DriverPackName = $null
        DriverPackOffline = $null
        DriverPackSource = $null
        DriverPackUrl = $null
        Function = $MyInvocation.MyCommand.Name
        GetDiskFixed = $null
        GetFeatureUpdate = $null
        GetMyDriverPack = $null
        HPIARun = $null
        HPTPMUpdate = $null
        HPBIOSUpdate = $null
        ImageCount = $null
        ImageFileFullName = $null
        ImageFileItem = $null
        ImageFileName = $null
        ImageFileSource = $null
        ImageFileDestination = $null
        ImageFileUrl = $null
        IsOnBattery = Get-OSDGather -Property IsOnBattery
        IsoMountDiskImage = $null
        IsoGetDiskImage = $null
        IsoGetVolume = $null
        Manufacturer = Get-MyComputerManufacturer -Brief
        OOBEDeployJsonChildItem = $null
        OOBEDeployJsonItem = $null
        OOBEDeployJsonName = $null
        OOBEDeployJsonObject = $null
        ODTConfigFile = 'C:\OSDCloud\ODT\Config.xml'
        ODTFile = $null
        ODTFiles = $null
        ODTSetupFile = $null
        ODTSource = $null
        ODTTarget = 'C:\OSDCloud\ODT'
        ODTTargetData = 'C:\OSDCloud\ODT\Office'
        OSBuild = $null
        OSBuildMenu = $null
        OSBuildNames = $null
        OSEdition = $null
        OSEditionId = $null
        OSEditionMenu = $null
        OSEditionNames = $null
        OSImageIndex = 1
        OSLanguage = $null
        OSLanguageMenu = $null
        OSLanguageNames = $null
        OSLicense = $null
        OSVersion = 'Windows 10'
        Product = Get-MyComputerProduct
        Restart = [bool]$false
        Screenshot = $null
        SectionPassed = $true
        Shutdown = [bool]$false
        SkipAutopilot = [bool]$false
        SkipAutopilotOOBE = [bool]$false
        SkipODT = [bool]$false
        SkipOOBEDeploy = [bool]$false
        RecoveryPartition = [bool]$true
        Test = [bool]$false
        TimeEnd = $null
        TimeSpan = $null
        TimeStart = Get-Date
        Transcript = $null
        USBPartitions = $null
        Version = [Version](Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
        ZTI = [bool]$false
    }
    #endregion
    #=================================================
    #region Set Pre-Merge Defaults
    #=================================================
    if (Test-IsVM) {
        $Global:OSDCloud.RecoveryPartition = $false
    }

    <# if ($Global:OSDCloud.ZTI -eq $true) {
        $Global:OSDCloud.ClearDiskConfirm = $false
    } #>
    #endregion
    #=================================================
    #region Merge Parameters
    #=================================================
    if ($Global:StartOSDCloud) {
        foreach ($Key in $Global:StartOSDCloud.Keys) {
            $Global:OSDCloud.$Key = $Global:StartOSDCloud.$Key
        }
    }
    if ($Global:MyOSDCloud) {
        foreach ($Key in $Global:MyOSDCloud.Keys) {
            $Global:OSDCloud.$Key = $Global:MyOSDCloud.$Key
        }
    }
    #endregion
    #=================================================
    #region Set Post-Merge Defaults
    #=================================================
    $Global:OSDCloud.Version = [Version](Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    #endregion
    #=================================================
    #region OSDCloudLogs
    #=================================================
    if ($env:SystemDrive -eq 'X:') {
        $OSDCloudLogs = "$env:SystemDrive\OSDCloud\Logs"
        if (-not (Test-Path $OSDCloudLogs)) {
            New-Item $OSDCloudLogs -ItemType Directory -Force | Out-Null
        }
    }
    #endregion
    #=================================================
    #region Fixed Disks
    #=================================================
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Validate Fixed Disks"
    $Global:OSDCloud.SectionPassed = $false

    $Global:OSDCloud.GetDiskFixed = Get-Disk.fixed | Where-Object {$_.IsBoot -eq $false} | Sort-Object Number

    if ($Global:OSDCloud.GetDiskFixed) {
        $Global:OSDCloud.SectionPassed = $true
    }
    else {
        $Global:OSDCloud.SectionPassed = $false
    }

    if ($Global:OSDCloud.SectionPassed -eq $false) {
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Unable to locate a Fixed Disk. You may need to add additional HDC Drivers to WinPE"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    #region Validate Operating System Source
    #=================================================
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Validate Operating System Source"
    $Global:OSDCloud.SectionPassed = $false

    if ($Global:OSDCloud.AzOSDCloudImage) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileItem) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileDestination) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileUrl) {
        $Global:OSDCloud.SectionPassed = $true
    }

    if ($Global:OSDCloud.SectionPassed -eq $false) {
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "An Operating System Source was not specified by any required Variables"
        Write-Warning "Invoke-OSDCloud should not be run directly unless you know what you are doing"
        Write-Warning "Try using Start-OSDCloud, Start-OSDCloudGUI, or Start-AzOSDCloudGUI"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    #region Autopilot Profiles
    #=================================================
    if ($Global:OSDCloud.SkipAutopilot -ne $true) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Autopilot Configuration"

        if ($Global:OSDCloud.AutopilotJsonObject) {
            Write-Host -ForegroundColor DarkGray 'Importing AutopilotJsonObject'
        }
        elseif ($Global:OSDCloud.AutopilotJsonUrl) {
            Write-Host -ForegroundColor DarkGray "Importing Autopilot Configuration $($Global:OSDCloud.AutopilotJsonUrl)"
            if (Test-WebConnection -Uri $Global:OSDCloud.AutopilotJsonUrl) {
                $Global:OSDCloud.AutopilotJsonObject = (Invoke-WebRequest -Uri $Global:OSDCloud.AutopilotJsonUrl).Content | ConvertFrom-Json
            }
        }
        elseif ($Global:OSDCloud.AutopilotJsonItem) {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonItem.Name -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonItem.Name -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"} | Select-Object -First 1
            if ($Global:OSDCloud.AutopilotJsonItem) {
                $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
            }
        }
        elseif ($Global:OSDCloud.AutopilotJsonName) {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonName -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonName -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"} | Select-Object -First 1
            if ($Global:OSDCloud.AutopilotJsonItem) {
                $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
            }
        }
        else {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name "*.json" -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name "*.json" -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"}

            if ($Global:OSDCloud.AutopilotJsonChildItem) {
                if ($Global:OSDCloud.ZTI -eq $true) {
                    $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Select-Object -First 1
                }
                else {
                    $Global:OSDCloud.AutopilotJsonItem = Select-OSDCloudAutopilotJsonItem
                }

                if ($Global:OSDCloud.AutopilotJsonItem) {
                    $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
                }
            }
        }

        if ($Global:OSDCloud.AutopilotJsonObject) {
            Write-Host -ForegroundColor DarkGray "OSDCloud will apply the following Autopilot Configuration as AutopilotConfigurationFile.json"
            $($Global:OSDCloud.AutopilotJsonObject) | Out-Host | Format-List
        }
        else {
            Write-Warning "AutopilotConfigurationFile.json will not be configured for this deployment"
        }
    }
    #endregion
    #=================================================
    #region Office Configuration
    if ($Global:OSDCloud.SkipODT -ne $true) {
        $Global:OSDCloud.ODTFiles = Find-OSDCloudODTFile
        
        if ($Global:OSDCloud.ODTFiles) {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select Office Deployment Tool Configuration"
        
            $Global:OSDCloud.ODTFile = Select-OSDCloudODTFile
            if ($Global:OSDCloud.ODTFile) {
                Write-Host -ForegroundColor DarkGray "Office Config: $($Global:OSDCloud.ODTFile.FullName)"
            } 
            else {
                Write-Warning "OSDCloud Office Config will not be configured for this deployment"
            }
        }
    }
    #endregion
    #=================================================
    #region Require WinPE
    #=================================================
    $Global:OSDCloud.Test = $true
    if ((Get-OSDGather -Property IsWinPE) -eq $false) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test WinPE"
        Write-Warning "OSDCloud can only be run from WinPE"
        $Global:OSDCloud.Test = $true
        Write-Warning "Test: $($Global:OSDCloud.Test)"
        #Write-Warning "OSDCloud Failed!"
        Start-Sleep -Seconds 5
        #Break
    }
    else {
        $Global:OSDCloud.Test = $false
    }
    #endregion
    #=================================================
    #region Remove USB Partition Access Path
    #=================================================
    $Global:OSDCloud.USBPartitions = Get-Partition.usb
    if ($Global:OSDCloud.USBPartitions) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Removing USB drive letters"
        Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/storage/remove-partitionaccesspath"
        Write-Verbose -Message "Partition Access Paths are being removed from USB Drive Letters"
        Write-Verbose -Message "This prevents issues when Drive Letters are reassigned"

        if ($Global:OSDCloud.Test -eq $false) {
            foreach ($USBPartition in $Global:OSDCloud.USBPartitions) {
                Write-Verbose -Message "Remove-PartitionAccessPath -DiskNumber $($USBPartition.DiskNumber) -PartitionNumber $($USBPartition.PartitionNumber) -AccessPath $($USBPartition.DriveLetter):"
                Remove-PartitionAccessPath -DiskNumber $USBPartition.DiskNumber -PartitionNumber $USBPartition.PartitionNumber -AccessPath "$($USBPartition.DriveLetter):"
                Start-Sleep -Seconds 3
            }
        }
    }
    #endregion
    #=================================================
    #region Clear-Disk
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Clear-Disk"
    Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/storage/clear-disk"
    Write-Verbose -Message "Fixed Disks must be cleared before new partitions can be created"

    if (($Global:OSDCloud.ZTI -eq $true) -and (($Global:OSDCloud.GetDiskFixed | Measure-Object).Count -lt 2)) {
        Write-Verbose -Message "Clear-Disk.fixed -Force -NoResults -Confirm:$false"
        if ($Global:OSDCloud.Test -eq $false) {
            Clear-Disk.fixed -Force -NoResults -Confirm:$false -ErrorAction Stop
        }
    }
    else {
        Write-Verbose -Message "Clear-Disk.fixed -Force -NoResults"
        if ($Global:OSDCloud.Test -eq $false) {
            Clear-Disk.fixed -Force -NoResults -ErrorAction Stop
        }
    }
    #endregion
    #=================================================
    #region New-OSDisk
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) New-OSDisk"
    Write-Verbose -Message "New Partitions will be created using Microsoft Standard Layout"
    Write-Verbose -Message "https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions"
    if ($Global:OSDCloud.RecoveryPartition -eq $false) {
        Write-Verbose -Message "New-OSDisk -NoRecoveryPartition -Force"
        if ($Global:OSDCloud.Test -eq $false) {
            New-OSDisk -PartitionStyle GPT -NoRecoveryPartition -Force -ErrorAction Stop
        }
        Write-Host "=========================================================================" -ForegroundColor Cyan
        Write-Host "| SYSTEM | MSR |                    WINDOWS                             |" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor Cyan
    }
    else {
        Write-Verbose -Message "New-OSDisk -Force"
        if ($Global:OSDCloud.Test -eq $false) {
            New-OSDisk -PartitionStyle GPT -Force -ErrorAction Stop
        }
        Write-Host "=========================================================================" -ForegroundColor Cyan
        Write-Host "| SYSTEM | MSR |                    WINDOWS                  | RECOVERY |" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor Cyan
    }
    #Wait a few seconds to make sure the Disk is set
    Start-Sleep -Seconds 5

    #Make sure that there is a PSDrive 
    if (-NOT (Get-PSDrive -Name 'C')) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "New-OSDisk didn't work. There is no PSDrive FileSystem at C:\"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    #region USB Add Partition Access Path
    #=================================================
    if ($Global:OSDCloud.USBPartitions) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Restoring USB Drive Letters"
        Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/storage/add-partitionaccesspath"

        if ($Global:OSDCloud.Test -eq $false) {
            foreach ($USBPartition in $Global:OSDCloud.USBPartitions) {
                Write-Verbose -Message "Add-PartitionAccessPath -DiskNumber $($USBPartition.DiskNumber) -PartitionNumber $($USBPartition.PartitionNumber) -AssignDriveLetter"
                Add-PartitionAccessPath -DiskNumber $USBPartition.DiskNumber -PartitionNumber $USBPartition.PartitionNumber -AssignDriveLetter
                Start-Sleep -Seconds 5
            }
        }
    }
    #endregion
    #=================================================
    #region Screenshot
    #=================================================
    if ($Global:OSDCloud.Screenshot) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Moving Screenshots to C:\OSDCloud\ScreenPNG"
        Write-Verbose -Message "https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy"
        Stop-ScreenPNGProcess
        Invoke-Exe robocopy "$($Global:OSDCloud.Screenshot)" C:\OSDCloud\ScreenPNG *.* /s /ndl /nfl /njh /njs
        Start-ScreenPNGProcess -Directory 'C:\OSDCloud\ScreenPNG'
        $Global:OSDCloud.Screenshot = 'C:\OSDCloud\ScreenPNG'
    }
    #endregion
    #=================================================
    #region Start Transcript
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Saving PowerShell Transcript to C:\OSDCloud\Logs"
    Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.host/start-transcript"

    if (-NOT (Test-Path 'C:\OSDCloud\Logs')) {
        New-Item -Path 'C:\OSDCloud\Logs' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    
    $Global:OSDCloud.Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Deploy-OSDCloud.log"
    Start-Transcript -Path (Join-Path 'C:\OSDCloud\Logs' $Global:OSDCloud.Transcript) -ErrorAction Ignore
    #endregion
    #=================================================
    #region High Performance
    #=================================================
    if ($Global:StartOSDCloud.IsOnBattery -eq $false) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Enable Powercfg High Performance"
        Write-Verbose -Message "https://docs.microsoft.com/en-us/windows/win32/power/power-policy-settings"
        Write-Verbose -Message "High Performance Power Plan is enabled to speed up OSDCloud performance"
        if ($Global:OSDCloud.Test -eq $false) {
            Invoke-Exe powercfg.exe -SetActive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
    }
    #endregion
    #=================================================
    #region Image File Offline
    #=================================================
    if ($Global:OSDCloud.ImageFileItem) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Copy Offline Windows Image (Copy-Item)"
        Write-Verbose -Message "Copying Microsoft Windows Image from Offline Source"

        #It's possible that Drive Letters may have changed if a USB is used

        #Check to see if the image file exists already after the USB Drive has been reinitialized
        if (Test-Path $Global:OSDCloud.ImageFileItem.FullName) {
            $Global:OSDCloud.ImageFileSource = Get-Item -Path $Global:OSDCloud.ImageFileItem.FullName
        }

        #Set the ImageFile Name if it does not exist
        if (!($Global:OSDCloud.ImageFileName)) {
            $Global:OSDCloud.ImageFileName = Split-Path -Path $Global:OSDCloud.ImageFileItem.FullName -Leaf
        }

        #If the Source did not exist after the USB, have to do a best guess
        if (!($Global:OSDCloud.ImageFileSource)) {
            $Global:OSDCloud.ImageFileSource = Find-OSDCloudFile -Name $Global:OSDCloud.ImageFileName -Path (Split-Path -Path (Split-Path -Path $Global:OSDCloud.ImageFileItem.FullName -Parent) -NoQualifier) | Where-Object {$_.FullName -notlike "C:*"} | Select-Object -First 1
        }

        #Now that we have an ImageFileSource, everything is good
        if ($Global:OSDCloud.ImageFileSource) {
            Write-Host -ForegroundColor DarkGray "-Source $($Global:OSDCloud.ImageFileSource.FullName)"
            if (!(Test-Path 'C:\OSDCloud\OS')) {
                New-Item -Path 'C:\OSDCloud\OS' -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            Copy-Item -Path $Global:OSDCloud.ImageFileSource.FullName -Destination 'C:\OSDCloud\OS' -Force
            if (Test-Path "C:\OSDCloud\OS\$($Global:OSDCloud.ImageFileSource.Name)") {
                $Global:OSDCloud.ImageFileDestination = Get-Item -Path "C:\OSDCloud\OS\$($Global:OSDCloud.ImageFileSource.Name)"
            }
        }
        if ($Global:OSDCloud.ImageFileDestination) {
            Write-Host -ForegroundColor DarkGray "-Destination $($Global:OSDCloud.ImageFileDestination.FullName)"
            $Global:OSDCloud.ImageFileUrl = $null
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not copy the Windows Image to C:\OSDCloud\OS"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region Get Image File
    #=================================================
    if ($Global:OSDCloud.AzOSDCloudImage) {
        #AzOSDCloud
    }
    elseif (!($Global:OSDCloud.ImageFileDestination) -and (!($Global:OSDCloud.ImageFileUrl))) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Get-FeatureUpdate"
        Write-Warning "Invoke-OSDCloud was not set properly with an OS to Download"
        Write-Warning "You should be using Start-OSDCloud or Start-OSDCloudGUI"
        Write-Warning "Invoke-OSDCloud should not be run directly unless you know what you are doing"
        Write-Warning "Windows 10 Enterprise is being downloaded and installed out of convenience only"

        if (!($Global:OSDCloud.GetFeatureUpdate)) {
            $Global:OSDCloud.GetFeatureUpdate = Get-FeatureUpdate
        }
        if ($Global:OSDCloud.GetFeatureUpdate) {
            $Global:OSDCloud.GetFeatureUpdate = $Global:OSDCloud.GetFeatureUpdate | Select-Object -Property CreationDate,KBNumber,Title,UpdateOS,UpdateBuild,UpdateArch,FileName, @{Name='SizeMB';Expression={[int]($_.Size /1024/1024)}},FileUri,Hash,AdditionalHash
            $Global:OSDCloud.ImageFileName = $Global:OSDCloud.GetFeatureUpdate.FileName
            $Global:OSDCloud.ImageFileUrl = $Global:OSDCloud.GetFeatureUpdate.FileUri
            $Global:OSDCloud.OSImageIndex = 6
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Unable to locate a Windows Feature Update"
            Write-Warning "OSDCloud cannot continue"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region Azure Storage Image Download
    #=================================================
    if ($Global:OSDCloud.AzOSDCloudImage) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Azure Storage Image Download"
        $Global:OSDCloud.AzOSDCloudImage | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudImage.json" -Encoding ascii -Width 2000

        $null = New-Item -Path 'C:\OSDCloud\OS' -ItemType Directory -Force -ErrorAction Ignore

        Get-AzStorageBlobContent -CloudBlob $Global:OSDCloud.AzOSDCloudImage.ICloudBlob -Context $Global:OSDCloud.AzOSDCloudImage.Context -Destination 'C:\OSDCloud\OS\'
        $Global:OSDCloud.ImageFileDestination = Get-ChildItem -Path 'C:\OSDCloud\OS\*' -Include *.wim,*.esd,*.iso | Select-Object -First 1
    }
    #endregion
    #=================================================
    #region Image Download
    #=================================================
    if (!($Global:OSDCloud.ImageFileDestination) -and ($Global:OSDCloud.ImageFileUrl)) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Download Operating System"
        Write-Host -ForegroundColor DarkGray "$($Global:OSDCloud.ImageFileUrl)"

        $null = New-Item -Path 'C:\OSDCloud\OS' -ItemType Directory -Force -ErrorAction Ignore

        if (Test-WebConnection -Uri $Global:OSDCloud.ImageFileUrl) {
            if ($Global:OSDCloud.ImageFileName) {
                #=================================================
                #	Cache to USB
                #=================================================
                $OSDCloudUSB = Get-Volume.usb | Where-Object {($_.FileSystemLabel -match 'OSDCloud') -or ($_.FileSystemLabel -match 'BHIMAGE')} | Where-Object {$_.SizeGB -ge 8} | Where-Object {$_.SizeRemainingGB -ge 5} | Select-Object -First 1
                
                if ($OSDCloudUSB -and $Global:OSDCloud.OSVersion -and $Global:OSDCloud.OSBuild) {
                    $OSDownloadChildPath = "$($OSDCloudUSB.DriveLetter):\OSDCloud\OS\$($Global:OSDCloud.OSVersion) $($Global:OSDCloud.OSBuild)"
                    Write-Host -ForegroundColor Yellow "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Downloading to OSDCloudUSB at $OSDownloadChildPath"

                    $OSDCloudUsbOS = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory "$OSDownloadChildPath" -DestinationName $Global:OSDCloud.ImageFileName

                    if ($OSDCloudUsbOS) {
                        Write-Host -ForegroundColor DarkGray "========================================================================="
                        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Copying Operating System to C:\OSDCloud\OS\$($OSDCloudUsbOS.Name)"
                        $null = Copy-Item -Path $OSDCloudUsbOS.FullName -Destination "C:\OSDCloud\OS" -Force

                        $Global:OSDCloud.ImageFileDestination = Get-Item "C:\OSDCloud\OS\$($OSDCloudUsbOS.Name)"
                    }
                }
                else {
                    $Global:OSDCloud.ImageFileDestination = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory 'C:\OSDCloud\OS' -DestinationName $Global:OSDCloud.ImageFileName -ErrorAction Stop
                }
            }
            else {
                $Global:OSDCloud.ImageFileDestination = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory 'C:\OSDCloud\OS' -ErrorAction Stop
            }
            if (!(Test-Path $Global:OSDCloud.ImageFileDestination.FullName)) {
                $Global:OSDCloud.ImageFileDestination = Get-ChildItem -Path 'C:\OSDCloud\OS\*' -Include *.wim,*.esd,*.iso | Select-Object -First 1
            }
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not verify an Internet connection for the Windows ImageFile"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }

        if ($Global:OSDCloud.ImageFileDestination) {
            Write-Verbose -Message "ImageFileDestination: $($Global:OSDCloud.ImageFileDestination.FullName)"
        }
    }
    #endregion
    #=================================================
    #region ImageFileDestination
    #=================================================
    if (-not ($Global:OSDCloud.ImageFileDestination)) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "The Windows Image Source did not download properly to the Destination"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    #region ISO Image File
    if ($Global:OSDCloud.ImageFileDestination.Extension -eq '.iso') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Windows ISO Deployment"

        $Global:OSDCloud.IsoGetDiskImage = Get-DiskImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName

        #ISO is already mounted (which should not be happening)
        if ($Global:OSDCloud.IsoGetDiskImage.Attached) {
            $Global:OSDCloud.IsoGetVolume = $Global:OSDCloud.IsoGetDiskImage | Get-Volume
            Write-Host -ForegroundColor DarkGray "Windows ISO is attached to Drive Letter $($Global:OSDCloud.IsoGetVolume.DriveLetter)"
        }
        else {
            Write-Host -ForegroundColor DarkGray "Mounting Windows ISO $($Global:OSDCloud.ImageFileDestination.FullName)"
            $Global:OSDCloud.IsoMountDiskImage = Mount-DiskImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName -PassThru -ErrorAction Stop

            if ($Global:OSDCloud.IsoMountDiskImage.Attached) {
                Start-Sleep -Seconds 10
                $Global:OSDCloud.IsoGetVolume = $Global:OSDCloud.IsoMountDiskImage | Get-Volume

                Write-Host -ForegroundColor DarkGray "Windows ISO is attached to Drive Letter $($Global:OSDCloud.IsoGetVolume.DriveLetter)"
            }
            else {
                Write-Host -ForegroundColor DarkGray "========================================================================="
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "The Windows ISO did not mount properly"
                Write-Warning "Press Ctrl+C to exit"
                Start-Sleep -Seconds 86400
                Exit
            }
        }
        $Global:OSDCloud.ImageFileDestination = Get-ChildItem -Path "$($Global:OSDCloud.IsoGetVolume.DriveLetter):\*" -Include *.wim,*.esd -Recurse | Sort-Object Length -Descending | Select-Object -First 1

        if (-not ($Global:OSDCloud.ImageFileDestination)) {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Unable to find a WIM or ESD file on the Mounted Windows ISO"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region ImageIndex
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Validate Windows Image Index"

    if (-NOT (Test-Path 'C:\OSDCloud\Temp')) {
        New-Item 'C:\OSDCloud\Temp' -ItemType Directory -Force | Out-Null
    }
    #=================================================
    #	Make sure the Windows Image exists
    #=================================================
    if (Test-Path $Global:OSDCloud.ImageFileDestination.FullName) {
        $Global:OSDCloud.ImageCount = (Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName).Count
        #=================================================
        #	Bad Image
        #=================================================
        if ($null -eq $Global:OSDCloud.ImageCount) {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not read the Windows Image properly"
            Start-Sleep -Seconds 86400
            Stop-Computer -Force
            Exit
        }
        #=================================================
        #TODO: Make sure the ImageIndex is 1
        #=================================================
        elseif ($Global:OSDCloud.ImageCount -eq 1) {
            $Global:OSDCloud.OSImageIndex = 1
        }
        #=================================================
        #	AUTO ImageIndex
        #=================================================
        elseif ($Global:OSDCloud.OSImageIndex -match 'AUTO') {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        elseif (-not ($Global:OSDCloud.OSImageIndex)) {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        elseif ($null -eq $Global:OSDCloud.OSImageIndex) {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        #=================================================
        #	Home Single Language Correction
        #=================================================
        if (($OSLicense -eq 'Retail') -and ($Global:OSDCloud.ImageCount -eq 9)) {
            if ($OSEdition -eq 'Home Single Language') {
                Write-Host -ForegroundColor DarkGray "========================================================================="
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Restart OSDCloud and select a different Edition"
                Start-Sleep -Seconds 86400
                Stop-Computer -Force
                Exit
            }
            if ($OSEdition -notmatch 'Home') {
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Adjusting selected ImageIndex by -1"
                $Global:OSDCloud.OSImageIndex = ($Global:OSDCloud.OSImageIndex - 1)
            }
        }
    }
    else {
        #=================================================
        #	FAILED
        #=================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Could not find a proper Windows Image for deployment"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }

    if ($Global:OSDCloud.OSImageIndex -eq 'AUTO') {
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select the Windows Image to expand"
        $SelectedWindowsImage = Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName | Where-Object {$_.ImageSize -gt 3000000000}

        if ($SelectedWindowsImage) {
            $SelectedWindowsImage | Select-Object -Property ImageIndex, ImageName | Format-Table | Out-Host
    
            do {
                $SelectReadHost = Read-Host -Prompt "Select an Image to apply by ImageIndex [Number]"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $SelectedWindowsImage.ImageIndex))))
    
            #$Global:OSDCloud.OSImageIndex = $SelectedWindowsImage | Where-Object {$_.ImageIndex -eq $SelectReadHost}
            $Global:OSDCloud.OSImageIndex = $SelectReadHost
        }
    }
    #endregion
    #=================================================
    #region Expand-WindowsImage
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Expand-WindowsImage"
    #Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/dism/expand-windowsimage"

    if (-NOT (Test-Path 'C:\OSDCloud\Temp')) {
        New-Item 'C:\OSDCloud\Temp' -ItemType Directory -Force | Out-Null
    }

    if (Test-Path $Global:OSDCloud.ImageFileDestination.FullName) {
        $Global:OSDCloud.ImageCount = (Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName).Count

        if ($null -eq $Global:OSDCloud.ImageCount) {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not read the Windows Image properly"
            Start-Sleep -Seconds 86400
            Stop-Computer -Force
            Exit
        }
        elseif ($Global:OSDCloud.ImageCount -eq 1) {
            $Global:OSDCloud.OSImageIndex = 1
        }
        elseif ((!($Global:OSDCloud.OSImageIndex)) -or ($Global:OSDCloud.OSImageIndex -eq 'Auto')) {
            Write-Warning "No ImageIndex is specified, setting ImageIndex = 1"
            $Global:OSDCloud.OSImageIndex = 1
        }
        #=================================================
        #	FAILED
        #=================================================
        if (($OSLicense -eq 'Retail') -and ($Global:OSDCloud.ImageCount -eq 9)) {
            if ($OSEdition -eq 'Home Single Language') {
                Write-Host -ForegroundColor DarkGray "========================================================================="
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Restart OSDCloud and select a different Edition"
                Start-Sleep -Seconds 86400
                Stop-Computer -Force
                Exit
            }
            if ($OSEdition -notmatch 'Home') {
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Adjusting selected ImageIndex by -1"
                $Global:OSDCloud.OSImageIndex = ($Global:OSDCloud.OSImageIndex - 1)
            }
        }

        Write-Host -ForegroundColor DarkGray "-ApplyPath 'C:\'"
        Write-Host -ForegroundColor DarkGray "-ImagePath $($Global:OSDCloud.ImageFileDestination.FullName)"
        Write-Host -ForegroundColor DarkGray "-Index $($Global:OSDCloud.OSImageIndex)"
        Write-Host -ForegroundColor DarkGray "-ScratchDirectory 'C:\OSDCloud\Temp'"
        if ($Global:OSDCloud.Test -eq $false) {
            Expand-WindowsImage -ApplyPath 'C:\' -ImagePath $Global:OSDCloud.ImageFileDestination.FullName -Index $Global:OSDCloud.OSImageIndex -ScratchDirectory 'C:\OSDCloud\Temp' -ErrorAction Stop

            $SystemDrive = Get-Partition | Where-Object {$_.Type -eq 'System'} | Select-Object -First 1
            if (-NOT (Get-PSDrive -Name S)) {
                $SystemDrive | Set-Partition -NewDriveLetter 'S'
            }
            bcdboot C:\Windows /s S: /f ALL
            Start-Sleep -Seconds 10
            $SystemDrive | Remove-PartitionAccessPath -AccessPath "S:\"
        }
    }
    else {
        #=================================================
        #	FAILED
        #=================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Could not find a proper Windows Image for deployment"
        Start-Sleep -Seconds 86400
        Stop-Computer -Force
        Exit
    }
    #endregion
    #=================================================
    #region Required Directories
    if (-NOT (Test-Path 'C:\Drivers')) {
        New-Item -Path 'C:\Drivers' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Panther')) {
        New-Item -Path 'C:\Windows\Panther' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Provisioning\Autopilot')) {
        New-Item -Path 'C:\Windows\Provisioning\Autopilot' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Setup\Scripts')) {
        New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    #endregion
    #=================================================
    #region Validate OSDCloud Driver Pack
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud DriverPack"
    if ($Global:OSDCloud.DriverPackName) {
        if ($Global:OSDCloud.DriverPackName -match 'None') {
            Write-Host -ForegroundColor DarkGray "DriverPack is set to None"
            $Global:OSDCloud.DriverPack = $null
        }
        elseif ($Global:OSDCloud.DriverPackName -match 'Microsoft Update Catalog') {
            Write-Host -ForegroundColor DarkGray "DriverPack is set to Microsoft Update Catalog"
            $Global:OSDCloud.DriverPack = $null
        }
        else {
            $Global:OSDCloud.DriverPack = Get-OSDCloudDriverPacks | Where-Object {$_.Name -eq $Global:OSDCloud.DriverPackName} | Select-Object -First 1
        }
    }
    else {
        $Global:OSDCloud.DriverPack = Get-OSDCloudDriverPack | Select-Object -First 1
    }

    if ($Global:OSDCloud.DriverPack) {
        $Global:OSDCloud.DriverPackBaseName = ($Global:OSDCloud.DriverPackFileName -split '.')[0]
    }

    if ($Global:OSDCloud.AzOSDCloudBlobDriverPack -and $Global:OSDCloud.DriverPackBaseName) {
        Write-Host -ForegroundColor DarkGray "Checking Azure for DriverPack"
        $Global:OSDCloud.AzOSDCloudDriverPack = $Global:OSDCloud.AzOSDCloudBlobDriverPack | Where-Object {$_.Name -match $Global:OSDCloud.DriverPackBaseName} | Select-Object -First 1
        $Global:OSDCloud.AzOSDCloudDriverPack | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudDriverPack.json" -Encoding ascii -Width 2000
    }

    if ($Global:OSDCloud.DriverPack) {
        $SaveMyDriverPack = $null

        $Global:OSDCloud.DriverPackBaseName = ($Global:OSDCloud.DriverPackFileName -split '.')[0]

        Write-Host -ForegroundColor DarkGray "Matching DriverPack identified"
        Write-Host -ForegroundColor DarkGray "-Name $($Global:OSDCloud.DriverPack.Name)"
        Write-Host -ForegroundColor DarkGray "-BaseName $($Global:OSDCloud.DriverPackBaseName)"
        Write-Host -ForegroundColor DarkGray "-Product $($Global:OSDCloud.DriverPack.Product)"
        Write-Host -ForegroundColor DarkGray "-FileName $($Global:OSDCloud.DriverPack.FileName)"
        Write-Host -ForegroundColor DarkGray "-Url $($Global:OSDCloud.DriverPack.Url)"

        $Global:StartOSDCloud.DriverPackOffline = Find-OSDCloudFile -Name $Global:StartOSDCloud.DriverPack.FileName -Path '\OSDCloud\DriverPacks\' | Sort-Object FullName
        $Global:StartOSDCloud.DriverPackOffline = $Global:StartOSDCloud.DriverPackOffline | Where-Object {$_.FullName -notlike "C*"} | Where-Object {$_.FullName -notlike "X*"} | Select-Object -First 1

        if ($Global:OSDCloud.DriverPackOffline) {
            Write-Host -ForegroundColor DarkGray "Matching DriverPack is available on OSDCloudUSB"
            Write-Host -ForegroundColor DarkGray $Global:StartOSDCloud.DriverPack.Name
            Write-Host -ForegroundColor DarkGray $Global:StartOSDCloud.DriverPackOffline.FullName
            #$Global:OSDCloud.DriverPackSource = Find-OSDCloudFile -Name (Split-Path -Path $Global:OSDCloud.DriverPackOffline -Leaf) -Path (Split-Path -Path (Split-Path -Path $Global:OSDCloud.DriverPackOffline.FullName -Parent) -NoQualifier) | Select-Object -First 1
            $Global:OSDCloud.DriverPackSource = $Global:StartOSDCloud.DriverPackOffline
        }

        if ($Global:OSDCloud.DriverPackSource) {
            Write-Host -ForegroundColor DarkGray "Copying matching DriverPack from OSDCloudUSB to C:\Drivers"
            Write-Host -ForegroundColor DarkGray "-DriverPackSource $($Global:OSDCloud.DriverPackSource.FullName)"
            Copy-Item -Path $Global:OSDCloud.DriverPackSource.FullName -Destination 'C:\Drivers' -Force

            $Global:OSDCloud.DriverPackExpand = $true
        }
        elseif ($Global:OSDCloud.AzOSDCloudDriverPack) {
            Write-Host -ForegroundColor DarkGray "Copying matching DriverPack from Azure Storage to C:\Drivers"    
            $null = New-Item -Path 'C:\OSDCloud\Drivers' -ItemType Directory -Force -ErrorAction Ignore
    
            Get-AzStorageBlobContent -CloudBlob $Global:OSDCloud.AzOSDCloudDriverPack.ICloudBlob -Context $Global:OSDCloud.AzOSDCloudDriverPack.Context -Destination 'C:\Drivers\'

            $Global:OSDCloud.DriverPackExpand = $true
        }
        elseif ($Global:OSDCloud.DriverPack.Guid) {
            $SaveMyDriverPack = Save-MyDriverPack -DownloadPath 'C:\Drivers' -Expand -Guid $Global:OSDCloud.DriverPack.Guid
        }

        if ($Global:OSDCloud.DriverPackExpand) {
            $DriverPacks = Get-ChildItem -Path 'C:\Drivers' -File

            foreach ($Item in $DriverPacks) {
                $SaveMyDriverPack = $Item.FullName
                $ExpandFile = $Item.FullName
                Write-Verbose -Verbose "DriverPack: $ExpandFile"
                #=================================================
                #   Cab
                #=================================================
                if ($Item.Extension -eq '.cab') {
                    $DestinationPath = Join-Path $Item.Directory $Item.BaseName
        
                    if (-NOT (Test-Path "$DestinationPath")) {
                        New-Item $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    
                        Write-Verbose -Verbose "Expanding CAB Driver Pack to $DestinationPath"
                        Expand -R "$ExpandFile" -F:* "$DestinationPath" | Out-Null
                    }
                    Continue
                }
                #=================================================
                #   Zip
                #=================================================
                if ($Item.Extension -eq '.zip') {
                    $DestinationPath = Join-Path $Item.Directory $Item.BaseName
    
                    if (-NOT (Test-Path "$DestinationPath")) {
                        Write-Verbose -Verbose "Expanding ZIP Driver Pack to $DestinationPath"
                        Expand-Archive -Path $ExpandFile -DestinationPath $DestinationPath -Force
                    }
                    Continue
                }
                #=================================================
            }
        }

        if ($SaveMyDriverPack) {
            if (-not ($Global:OSDCloud.DriverPackSource)) {
                #=================================================
                #	Cache to OSDCloudUSB
                #=================================================
                $OSDCloudUSB = Get-Volume.usb | Where-Object {($_.FileSystemLabel -match 'OSDCloud') -or ($_.FileSystemLabel -match 'BHIMAGE')} | Where-Object {$_.SizeGB -ge 8} | Where-Object {$_.SizeRemainingGB -ge 2} | Select-Object -First 1
                if ($OSDCloudUSB) {
                    $OSDCloudUSBDestination = "$($OSDCloudUSB.DriveLetter):\OSDCloud\DriverPacks\$($Global:OSDCloud.Manufacturer)"
                    Write-Host -ForegroundColor Yellow "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Copying Driver Pack to OSDCloudUSB at $OSDCloudUSBDestination"
                    If (! (Test-Path $OSDCloudUSBDestination)) {
                        $null = New-Item -Path $OSDCloudUSBDestination -ItemType Directory -Force
                    }
                    $Results = Copy-Item -Path $SaveMyDriverPack.FullName -Destination $OSDCloudUSBDestination -Force -PassThru -ErrorAction Stop
                }
            }
        }
    }
    #=================================================
    #	ApplyCatalogFirmware
    #   This section will download any available
    #   Firmware updates from Microsoft Update Catalog
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Microsoft Catalog Firmware Update (Save-SystemFirmwareUpdate)"

    if ($Global:OSDCloud.ApplyCatalogFirmware -eq $false) {
        Write-Host -ForegroundColor DarkGray "Microsoft Catalog Firmware Update is not enabled for this deployment"
    }
    elseif (Test-IsVM) {
        Write-Host -ForegroundColor DarkGray "Microsoft Catalog Firmware Update is not enabled for Virtual Machines"
    }
    elseif ($OSDCloud.IsOnBattery -eq $true) {
        Write-Host -ForegroundColor DarkGray "Microsoft Catalog Firmware Update is not enabled for devices on battery power"
    }
    else {
        if (Test-MicrosoftUpdateCatalog) {
            Write-Host -ForegroundColor DarkGray "Firmware Updates will be downloaded from Microsoft Update Catalog to C:\Drivers\Firmware"
            Write-Host -ForegroundColor DarkGray "Some systems do not support a driver Firmware Update"
            Write-Host -ForegroundColor DarkGray "You may have to enable this setting in your BIOS or Firmware Settings"
            Write-Verbose -Message "Save-SystemFirmwareUpdate -DestinationDirectory 'C:\Drivers\Firmware'"
    
            Save-SystemFirmwareUpdate -DestinationDirectory 'C:\Drivers\Firmware'
        }
        else {
            #TODO add some notification
        }
    }
    #=================================================
    #	ApplyCatalogDrivers
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    if ($Global:OSDCloud.ApplyCatalogDrivers -eq $false) {
        Write-Host -ForegroundColor DarkGray "Microsoft Catalog Drivers is not enabled for this deployment"
    }
    elseif (Test-IsVM) {
        Write-Host -ForegroundColor DarkGray "Microsoft Catalog Drivers is not enabled for Virtual Machines"
    }
    else {
        if (Test-MicrosoftUpdateCatalog) {
            if (($null -eq $SaveMyDriverPack) -or ($Global:OSDCloud.DriverPackName -match 'Microsoft Update Catalog')) {
                Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Save-MsUpCatDriver (All Devices)"
                Write-Host -ForegroundColor DarkGray "Drivers for all devices will be downloaded from Microsoft Update Catalog to C:\Drivers"

                Write-Host -ForegroundColor DarkGray "Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers'"
                Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers'
            }
            else {
                Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Save-MsUpCatDriver (Network)"
                Write-Host -ForegroundColor DarkGray "Drivers for Network devices will be downloaded from Microsoft Update Catalog to C:\Drivers"

                Write-Host -ForegroundColor DarkGray "Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers' -PNPClass 'Net'"
                Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers' -PNPClass 'Net'
            }
        }
    }
    #=================================================
    #   Add-OfflineServicingWindowsDriver
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Add Windows Driver with Offline Servicing (Add-OfflineServicingWindowsDriver)"
    Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/dism/add-windowsdriver"
    Write-Host -ForegroundColor DarkGray "Drivers in C:\Drivers are being added to the offline Windows Image"
    Write-Host -ForegroundColor DarkGray "This process can take up to 20 minutes"
    Write-Verbose -Message "Add-OfflineServicingWindowsDriver"
    if ($Global:OSDCloud.Test -eq $false) {
        Add-OfflineServicingWindowsDriver
    }
    #=================================================
    #   Set-OSDCloudUnattendSpecialize
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set Specialize Unattend.xml (Set-OSDCloudUnattendSpecialize)"
    Write-Host -ForegroundColor DarkGray "C:\Windows\Panther\Invoke-OSDSpecialize.xml is being applied as an Unattend file"
    Write-Host -ForegroundColor DarkGray "This will enable the extraction and installation of HP, Lenovo, and Microsoft Surface Drivers if necessary"
    Write-Verbose -Message "Set-OSDCloudUnattendSpecialize"
    if ($Global:OSDCloud.Test -eq $false) {
        Set-OSDCloudUnattendSpecialize
        #Set-OSDxCloudUnattendSpecialize -Verbose
    }
    #=================================================
    #   HP Updates Config for Specialize Phase
    #=================================================
    if ($Manufacturer -eq 'HP') {Write-Host -ForegroundColor DarkGray "HPIARun = $($Global:OSDCloud.HPIARun) | HPTPMUpdate = $($Global:OSDCloud.HPTPMUpdate) | HPBIOSUpdate = $($Global:OSDCloud.HPBIOSUpdate)"} #Debug
    if (($Global:OSDCloud.HPIARun -eq $true) -or ($Global:OSDCloud.HPTPMUpdate -eq $true) -or ($Global:OSDCloud.HPBIOSUpdate -eq $true)){
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "Adding HP Tasks into JSON Config File for Action during Specialize" 
    Write-Host -ForegroundColor DarkGray "HPIARun = $($Global:OSDCloud.HPIARun) | HPTPMUpdate = $($Global:OSDCloud.HPTPMUpdate) | HPBIOSUpdate = $($Global:OSDCloud.HPBIOSUpdate)" 
        $HPHashTable = @{
            'HPUpdates' = @{
                'HPIARun' = $Global:OSDCloud.HPIARun
                'HPTPMUpdate' = $Global:OSDCloud.HPTPMUpdate
                'HPBIOSUpdate' = $Global:OSDCloud.HPBIOSUpdate
            }
        }
        $HPHashVar = $HPHashTable | ConvertTo-Json
        $ConfigPath = "c:\osdcloud\configs"
        $ConfigFile = "$ConfigPath\HP.JSON"
        try {[void][System.IO.Directory]::CreateDirectory($ConfigPath)}
        catch {}
        $HPHashVar | Out-File $ConfigFile
    }
    
    #=================================================
    #   AutopilotConfigurationFile.json
    #=================================================
    if ($Global:OSDCloud.AutopilotJsonObject) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying AutopilotConfigurationFile.json"
        Write-Host -ForegroundColor DarkGray 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json'
        $Global:OSDCloud.AutopilotJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json' -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   OSDeploy.OOBEDeploy.json
    #=================================================
    if ($Global:OSDCloud.OOBEDeployJsonObject) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying OSDeploy.OOBEDeploy.json"
        Write-Host -ForegroundColor DarkGray 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json'

        If (!(Test-Path "C:\ProgramData\OSDeploy")) {
            New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
        }
        $Global:OSDCloud.OOBEDeployJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json' -Encoding ascii -Width 2000 -Force
        #================================================
        #   WinPE PostOS
        #   Set OOBEDeploy CMD.ps1
        #================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest OSD Module
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose

:: Start-OOBEDeploy
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy

exit
'@
        $SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   OSDeploy.AutopilotOOBE.json
    #=================================================
    if ($Global:OSDCloud.AutopilotOOBEJsonObject) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying OSDeploy.AutopilotOOBE.json"
        Write-Host -ForegroundColor DarkGray 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json'

        If (!(Test-Path "C:\ProgramData\OSDeploy")) {
            New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
        }
        $Global:OSDCloud.AutopilotOOBEJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json' -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   Stage Office Config
    #=================================================
    if ($Global:OSDCloud.ODTFile) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Stage Office Config"

        if (!(Test-Path $Global:OSDCloud.ODTTarget)) {
            New-Item -Path $Global:OSDCloud.ODTTarget -ItemType Directory -Force | Out-Null
        }

        if (Test-Path $Global:OSDCloud.ODTFile.FullName) {
            Copy-Item -Path $Global:OSDCloud.ODTFile.FullName -Destination $Global:OSDCloud.ODTConfigFile -Force
        }

        $Global:OSDCloud.ODTSetupFile = Join-Path $Global:OSDCloud.ODTFile.Directory 'setup.exe'
        Write-Verbose -Verbose "ODTSetupFile: $($Global:OSDCloud.ODTSetupFile)"
        if (Test-Path $Global:OSDCloud.ODTSetupFile) {
            Copy-Item -Path $Global:OSDCloud.ODTSetupFile -Destination $Global:OSDCloud.ODTTarget -Force
        }

        $Global:OSDCloud.ODTSource = Join-Path $Global:OSDCloud.ODTFile.Directory 'Office'
        Write-Verbose -Verbose "ODTSource: $($Global:OSDCloud.ODTSource)"
        if (Test-Path $Global:OSDCloud.ODTSource) {
            Invoke-Exe robocopy "$($Global:OSDCloud.ODTSource)" "$($Global:OSDCloud.ODTTargetData)" *.* /s /ndl /nfl /z /b
        }
    }
    #=================================================
    #   Save PowerShell Modules to OSDisk
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Saving PowerShell Modules and Scripts"
    if ($Global:OSDCloud.Test -eq $false) {
        $PowerShellSavePath = 'C:\Program Files\WindowsPowerShell'

        if (-NOT (Test-Path "$PowerShellSavePath\Configuration")) {
            New-Item -Path "$PowerShellSavePath\Configuration" -ItemType Directory -Force | Out-Null
        }
        if (-NOT (Test-Path "$PowerShellSavePath\Modules")) {
            New-Item -Path "$PowerShellSavePath\Modules" -ItemType Directory -Force | Out-Null
        }
        if (-NOT (Test-Path "$PowerShellSavePath\Scripts")) {
            New-Item -Path "$PowerShellSavePath\Scripts" -ItemType Directory -Force | Out-Null
        }
        
        if (Test-WebConnection -Uri "https://www.powershellgallery.com") {
            Copy-PSModuleToFolder -Name OSD -Destination "$PowerShellSavePath\Modules"

            try {
                Save-Module -Name OSD -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module OSD to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name PackageManagement -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module PackageManagement to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name PowerShellGet -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module PowerShellGet to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name WindowsAutopilotIntune -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module WindowsAutopilotIntune to $PowerShellSavePath\Modules"
            }

            try {
                Save-Script -Name Get-WindowsAutopilotInfo -Path "$PowerShellSavePath\Scripts" -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Script Get-WindowsAutopilotInfo to $PowerShellSavePath\Scripts"
            }
        }
        else {
            Write-Verbose -Verbose "Copy-PSModuleToFolder -Name OSD to $PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name OSD -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name PackageManagement -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name PowerShellGet -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name WindowsAutopilotIntune -Destination "$PowerShellSavePath\Modules"
        
            $OSDCloudOfflinePath = Find-OSDCloudOfflinePath
        
            foreach ($Item in $OSDCloudOfflinePath) {
                if (Test-Path "$($Item.FullName)\PowerShell\Required") {
                    Write-Host -ForegroundColor Cyan "Applying PowerShell Modules and Scripts in $($Item.FullName)\PowerShell\Required"
                    robocopy "$($Item.FullName)\PowerShell\Required" "$PowerShellSavePath" *.* /s /ndl /njh /njs
                }
            }
        }
    }
    #=================================================
    #	Deploy-OSDCloud Complete
    #=================================================
    $Global:OSDCloud.TimeEnd = Get-Date
    $Global:OSDCloud.TimeSpan = New-TimeSpan -Start $Global:OSDCloud.TimeStart -End $Global:OSDCloud.TimeEnd
    
    $Global:OSDCloud | ConvertTo-Json | Out-File -FilePath 'C:\OSDCloud\Logs\OSDCloud.json' -Encoding ascii -Width 2000 -Force
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Finished"
    Write-Host -ForegroundColor DarkGray "Completed in $($Global:OSDCloud.TimeSpan.ToString("mm' minutes 'ss' seconds'"))"
    #=================================================
    if ($Global:OSDCloud.Screenshot) {
        Start-Sleep 5
        Stop-ScreenPNGProcess
        Write-Host -ForegroundColor DarkGray "Screenshots: $($Global:OSDCloud.Screenshot)"
    }
    #=================================================
    if ($Global:OSDCloud.Restart) {
        Write-Warning "WinPE is restarting in 30 seconds"
        Write-Warning "Press CTRL + C to cancel"
        Start-Sleep -Seconds 30
        if ($Global:OSDCloud.Test -eq $false) {
            Restart-Computer
        }
    }
    #=================================================
    if ($Global:OSDCloud.Shutdown) {
        Write-Warning "WinPE will shutdown in 30 seconds"
        Write-Warning "Press CTRL + C to cancel"
        Start-Sleep -Seconds 30
        if ($Global:OSDCloud.Test -eq $false) {
            Stop-Computer
        }
    }
    #=================================================
    #	Stop-Transcript
    #=================================================
    if ($OSDCloud.Test -eq $true) {
        Stop-Transcript
    }
    #=================================================
}
