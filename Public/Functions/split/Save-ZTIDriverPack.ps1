function Save-ZTIDriverPack {
    [CmdletBinding()]
    param (
        [string]$Manufacturer = (Get-MyComputerManufacturer -Brief),
        [string]$Product = (Get-MyComputerProduct),
        [System.Management.Automation.SwitchParameter]$Expand
    )
    #=================================================
    #	Make sure we are running in a Task Sequence first
    #=================================================
    try {
        $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    }
    catch {
        $TSEnv = $false
    }

    if ($TSEnv -eq $false) {
        Write-Warning "This functions requires a running Task Sequence"
        Start-Sleep -Seconds 5
        Continue
    }
    #=================================================
    #	Get some Task Sequence variables
    #=================================================
    $DEPLOYROOT = $TSEnv.Value("DEPLOYROOT")
    $DEPLOYDRIVE = $TSEnv.Value("DEPLOYDRIVE") # Z:
    $OSVERSION = $TSEnv.Value("OSVERSION") # WinPE
    $RESOURCEDRIVE = $TSEnv.Value("RESOURCEDRIVE") # Z:
    $OSDISK = $TSEnv.Value("OSDISK") # E:
    $OSDANSWERFILEPATH = $TSEnv.Value("OSDANSWERFILEPATH") # E:\MININT\Unattend.xml
    $TARGETPARTITIONIDENTIFIER = $TSEnv.Value("TARGETPARTITIONIDENTIFIER") # [SELECT * FROM Win32_LogicalDisk WHERE Size = '134343553024' and VolumeName = 'Windows' and VolumeSerialNumber = '90D39B87']
    #=================================================
    #	Set some Variables
    #   DeployRootDriverPacks are where DriverPacks must be staged
    #   This is not working out so great at the moment, so I would suggest
    #   not doing this yet
    #=================================================
    $DeployRootDriverPacks = Join-Path $DEPLOYROOT 'DriverPacks'
    $OSDiskDrivers = Join-Path $OSDISK 'Drivers'
    #=================================================
    #	Create $OSDiskDrivers
    #=================================================
    if (-NOT (Test-Path -Path $OSDiskDrivers)) {
        New-Item -Path $OSDiskDrivers -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    if (-NOT (Test-Path -Path $OSDiskDrivers)) {
        Write-Warning "Could not create $OSDiskDrivers"
        Start-Sleep -Seconds 5
        Continue
    }
    #=================================================
    #	Start-Transcript
    #=================================================
    Start-Transcript -OutputDirectory $OSDiskDrivers
    #=================================================
    #	Copy-PSModuleToFolder
    #   The OSD Module needs to be available on the next boot for Specialize
    #   Drivers to work
    #=================================================
    if ($env:SystemDrive -eq 'X:') {
        Copy-PSModuleToFolder -Name OSD -Destination "$OSDISK\Program Files\WindowsPowerShell\Modules"
    }
    #=================================================
    #	Get-MyDriverPack
    #=================================================
    Write-Verbose -Verbose "Processing function Get-MyDriverPack"
    if ($Manufacturer -in ('Dell', 'HP', 'Lenovo', 'Microsoft')) {
        $GetMyDriverPack = Get-MyDriverPack -Manufacturer $Manufacturer -Product $Product
    }
    else {
        $GetMyDriverPack = Get-MyDriverPack -Product $Product
    }
    if (-NOT ($GetMyDriverPack)) {
        Write-Warning "There are no DriverPacks for this computer"
        Start-Sleep -Seconds 5
        Stop-Transcript
        Continue
    }
    #=================================================
    #	Get-MyDriverPack
    #=================================================
    Write-Verbose -Verbose "Name: $($GetMyDriverPack.Name)"
    Write-Verbose -Verbose "Product: $($GetMyDriverPack.Product)"
    Write-Verbose -Verbose "FileName: $($GetMyDriverPack.FileName)"
    Write-Verbose -Verbose "Url: $($GetMyDriverPack.Url)"
    $OSDiskDriversFile = Join-Path $OSDiskDrivers $GetMyDriverPack.FileName
    #=================================================
    #	MDT DeployRoot DriverPacks
    #   See if the DriverPack we need exists in $DeployRootDriverPacks
    #=================================================
    $BaseName = [io.path]::GetFileNameWithoutExtension($GetMyDriverPack.Filename)
    $DeployRootDriverPack = @()
    $DeployRootDriverPack = Get-ChildItem "$DeployRootDriverPacks\" -Include $BaseName* -File -Recurse -Force -ErrorAction Ignore | Select-Object -First 1
    if ($DeployRootDriverPack) {
        $OSDiskDriversFile = Join-Path $OSDiskDrivers $DeployRootDriverPack.Name
        Write-Verbose -Verbose "Source: $($DeployRootDriverPack.FullName)"
        Write-Verbose -Verbose "Destination: $OSDiskDriversFile"
        Copy-Item -Path $($DeployRootDriverPack.FullName) -Destination $OSDiskDrivers -Force
    }

    if (Test-Path $OSDiskDriversFile) {
        $GetItemOutFile = Get-Item $OSDiskDriversFile -ErrorAction SilentlyContinue
        Write-Verbose -Verbose "DriverPack is in place and ready to go"
    }
    else {
        #=================================================
        #	Curl
        #   Make sure Curl is available
        #=================================================
        if ((-NOT (Test-Path "$env:SystemRoot\System32\curl.exe")) -and (-NOT (Test-Path "$OSDISK\Windows\System32\curl.exe"))) {
            Write-Warning "Curl is required for this to function"
            Start-Sleep -Seconds 5
            Stop-Transcript
            Continue
        }
        if ((-NOT (Test-Path "$env:SystemRoot\System32\curl.exe")) -and (Test-Path "$OSDISK\Windows\System32\curl.exe")) {
            Copy-Item -Path "$OSDISK\Windows\System32\curl.exe" -Destination "$env:SystemRoot\System32\curl.exe" -Force
        }

        if (-NOT (Test-Path "$env:SystemRoot\System32\curl.exe")) {
            Write-Warning "Curl is required for this to function"
            Start-Sleep -Seconds 5
            Stop-Transcript
            Continue
        }
        #=================================================
        #	OSDCloud DriverPacks
        #   Finally, let's download the file and see where this goes
        #=================================================
        Save-WebFile -SourceUrl $GetMyDriverPack.Url -DestinationDirectory $OSDiskDrivers -DestinationName $GetMyDriverPack.FileName

        if (Test-Path $OSDiskDriversFile) {
            $GetItemOutFile = Get-Item $OSDiskDriversFile -ErrorAction SilentlyContinue
            Write-Verbose -Verbose "DriverPack is in place and ready to go"
        }
        else {
            Write-Warning "Could not download the DriverPack. Sorry!"
            Stop-Transcript
            Continue
        }
    }
    #=================================================
    #   Expand
    #=================================================
    if ($GetItemOutFile) {
        if ($PSBoundParameters.ContainsKey('Expand')) {
    
            $ExpandFile = $GetItemOutFile.FullName
            Write-Verbose -Message "DriverPack: $ExpandFile"
            #=================================================
            #   Cab
            #=================================================
            if ($GetItemOutFile.Extension -eq '.cab') {
                $DestinationPath = Join-Path $GetItemOutFile.Directory $GetItemOutFile.BaseName
        
                if (-NOT (Test-Path "$DestinationPath")) {
                    New-Item $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    
                    Write-Verbose -Verbose "Expanding CAB Driver Pack to $DestinationPath"
                    Expand -R "$ExpandFile" -F:* "$DestinationPath" | Out-Null
                }
            }
            #=================================================
            #   Dell
            #=================================================
            if (($GetItemOutFile.Extension -eq '.exe') -and ($env:SystemDrive -ne 'X:')) {
                if ($GetItemOutFile.VersionInfo.FileDescription -match 'Dell') {
                    Write-Verbose -Verbose "FileDescription: $($GetItemOutFile.VersionInfo.FileDescription)"
                    Write-Verbose -Verbose "ProductVersion: $($GetItemOutFile.VersionInfo.ProductVersion)"
    
                    $DestinationPath = Join-Path $GetItemOutFile.Directory $GetItemOutFile.BaseName
    
                    if (-NOT (Test-Path "$DestinationPath")) {
                        Write-Verbose -Verbose "Expanding Dell Driver Pack to $DestinationPath"
                        $null = New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                        Start-Process -FilePath $ExpandFile -ArgumentList "/s /e=`"$DestinationPath`"" -Wait
                    }
                }
            }
            #=================================================
            #   HP
            #=================================================
            if (($GetItemOutFile.Extension -eq '.exe') -and ($env:SystemDrive -ne 'X:')) {
                if (($GetItemOutFile.VersionInfo.InternalName -match 'hpsoftpaqwrapper') -or ($GetItemOutFile.VersionInfo.OriginalFilename -match 'hpsoftpaqwrapper.exe') -or ($GetItemOutFile.VersionInfo.FileDescription -like "HP *")) {
                    Write-Verbose -Message "FileDescription: $($GetItemOutFile.VersionInfo.FileDescription)"
                    Write-Verbose -Message "InternalName: $($GetItemOutFile.VersionInfo.InternalName)"
                    Write-Verbose -Message "OriginalFilename: $($GetItemOutFile.VersionInfo.OriginalFilename)"
                    Write-Verbose -Message "ProductVersion: $($GetItemOutFile.VersionInfo.ProductVersion)"
                        
                    $DestinationPath = Join-Path $GetItemOutFile.Directory $GetItemOutFile.BaseName
    
                    if (-NOT (Test-Path "$DestinationPath")) {
                        Write-Verbose -Verbose "Expanding HP Driver Pack to $DestinationPath"
                        Start-Process -FilePath $ExpandFile -ArgumentList "/s /e /f `"$DestinationPath`"" -Wait
                    }
                }
            }
            #=================================================
            #   Lenovo
            #=================================================
            if (($GetItemOutFile.Extension -eq '.exe') -and ($env:SystemDrive -ne 'X:')) {
                if (($GetItemOutFile.VersionInfo.FileDescription -match 'Lenovo') -or ($GetItemOutFile.Name -match 'tc_') -or ($GetItemOutFile.Name -match 'tp_') -or ($GetItemOutFile.Name -match 'ts_') -or ($GetItemOutFile.Name -match '500w') -or ($GetItemOutFile.Name -match 'sccm_') -or ($GetItemOutFile.Name -match 'm710e') -or ($GetItemOutFile.Name -match 'tp10') -or ($GetItemOutFile.Name -match 'tp8') -or ($GetItemOutFile.Name -match 'yoga')) {
                    Write-Verbose -Message "FileDescription: $($GetItemOutFile.VersionInfo.FileDescription)"
                    Write-Verbose -Message "ProductVersion: $($GetItemOutFile.VersionInfo.ProductVersion)"
    
                    $DestinationPath = Join-Path $GetItemOutFile.Directory 'SCCM'
    
                    if (-NOT (Test-Path "$DestinationPath")) {
                        Write-Verbose -Verbose "Expanding Lenovo Driver Pack to $DestinationPath"
                        Start-Process -FilePath $ExpandFile -ArgumentList "/SILENT /SUPPRESSMSGBOXES" -Wait
                    }
                }
            }
            #=================================================
            #   MSI
            #=================================================
            if (($GetItemOutFile.Extension -eq '.msi') -and ($env:SystemDrive -ne 'X:')) {
                $DestinationPath = Join-Path $GetItemOutFile.Directory $GetItemOutFile.BaseName
    
                if (-NOT (Test-Path "$DestinationPath")) {
                    #Need to sort out what to do here
                }
            }
            #=================================================
            #   Zip
            #=================================================
            if ($GetItemOutFile.Extension -eq '.zip') {
                $DestinationPath = Join-Path $GetItemOutFile.Directory $GetItemOutFile.BaseName
    
                if (-NOT (Test-Path "$DestinationPath")) {
                    Write-Verbose -Verbose "Expanding ZIP Driver Pack to $DestinationPath"
                    Expand-Archive -Path $ExpandFile -DestinationPath $DestinationPath -Force
                }
            }
            #=================================================
            #   Everything Else
            #=================================================
            #Write-Warning "Unable to expand $ExpandFile"
        }
    }
    Stop-Transcript
}
