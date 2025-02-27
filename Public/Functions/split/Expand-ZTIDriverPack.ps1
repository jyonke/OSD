function Expand-ZTIDriverPack {
    [CmdletBinding()]
    param ()
    #=================================================
    #	Set some Variables
    #=================================================
    $OSDiskDrivers = 'C:\Drivers'
    #=================================================
    #	Create $OSDiskDrivers
    #=================================================
    if (-NOT (Test-Path -Path $OSDiskDrivers)) {
        Write-Warning "Could not find $OSDiskDrivers"
        Start-Sleep -Seconds 5
        Continue
    }
    #=================================================
    #	Start-Transcript
    #=================================================
    Start-Transcript -OutputDirectory $OSDiskDrivers
    #=================================================
    #   Expand
    #=================================================
    $DriverPacks = Get-ChildItem -Path $OSDiskDrivers -File

    foreach ($Item in $DriverPacks) {
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

                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
                pnpunattend.exe AuditSystem /L
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
            }
            Continue
        }
        #=================================================
        #   Dell
        #=================================================
        if ($Item.Extension -eq '.exe') {
            if ($Item.VersionInfo.FileDescription -match 'Dell') {
                Write-Verbose -Verbose "FileDescription: $($Item.VersionInfo.FileDescription)"
                Write-Verbose -Verbose "ProductVersion: $($Item.VersionInfo.ProductVersion)"

                $DestinationPath = Join-Path $Item.Directory $Item.BaseName

                if (-NOT (Test-Path "$DestinationPath")) {
                    Write-Verbose -Verbose "Expanding Dell Driver Pack to $DestinationPath"
                    $null = New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                    Start-Process -FilePath $ExpandFile -ArgumentList "/s /e=`"$DestinationPath`"" -Wait

                    if ($Apply) {
                        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
                        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
                        pnpunattend.exe AuditSystem /L
                        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
                    }
                }
                Continue
            }
        }
        #=================================================
        #   HP
        #=================================================
        if ($Item.Extension -eq '.exe') {
            if (($Item.VersionInfo.InternalName -match 'hpsoftpaqwrapper') -or ($Item.VersionInfo.OriginalFilename -match 'hpsoftpaqwrapper.exe') -or ($Item.VersionInfo.FileDescription -like "HP *")) {
                Write-Verbose -Verbose "FileDescription: $($Item.VersionInfo.FileDescription)"
                Write-Verbose -Verbose "InternalName: $($Item.VersionInfo.InternalName)"
                Write-Verbose -Verbose "OriginalFilename: $($Item.VersionInfo.OriginalFilename)"
                Write-Verbose -Verbose "ProductVersion: $($Item.VersionInfo.ProductVersion)"
                
                $DestinationPath = Join-Path $Item.Directory $Item.BaseName

                if (-NOT (Test-Path "$DestinationPath")) {
                    Write-Verbose -Verbose "Expanding HP Driver Pack to $DestinationPath"
                    Start-Process -FilePath $ExpandFile -ArgumentList "/s /e /f `"$DestinationPath`"" -Wait

                    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
                    pnpunattend.exe AuditSystem /L
                    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
                }
                Continue
            }
        }
        #=================================================
        #   Lenovo
        #=================================================
        if ($Item.Extension -eq '.exe') {
            if (($GetItemOutFile.VersionInfo.FileDescription -match 'Lenovo') -or ($GetItemOutFile.Name -match 'tc_') -or ($GetItemOutFile.Name -match 'tp_') -or ($GetItemOutFile.Name -match 'ts_') -or ($GetItemOutFile.Name -match '500w') -or ($GetItemOutFile.Name -match 'sccm_') -or ($GetItemOutFile.Name -match 'm710e') -or ($GetItemOutFile.Name -match 'tp10') -or ($GetItemOutFile.Name -match 'tp8') -or ($GetItemOutFile.Name -match 'yoga')) {
                Write-Verbose -Verbose "FileDescription: $($Item.VersionInfo.FileDescription)"
                Write-Verbose -Verbose "ProductVersion: $($Item.VersionInfo.ProductVersion)"

                $DestinationPath = Join-Path $Item.Directory 'SCCM'

                if (-NOT (Test-Path "$DestinationPath")) {
                    Write-Verbose -Verbose "Expanding Lenovo Driver Pack to $DestinationPath"
                    Start-Process -FilePath $ExpandFile -ArgumentList "/SILENT /SUPPRESSMSGBOXES" -Wait

                    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
                    pnpunattend.exe AuditSystem /L
                    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
                }
                Continue
            }
        }
        #=================================================
        #   MSI
        #=================================================
        if ($Item.Extension -eq '.msi') {
            $DateStamp = Get-Date -Format yyyyMMddTHHmmss
            $logFile = '{0}-{1}.log' -f $ExpandFile,$DateStamp
            $MSIArguments = @(
                "/i"
                ('"{0}"' -f $ExpandFile)
                "/qb"
                "/norestart"
                "/L*v"
                $logFile
            )
            Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
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
            
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
                pnpunattend.exe AuditSystem /L
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
            }
            Continue
        }
        #=================================================
        #   Everything Else
        #=================================================
        Write-Warning "Unable to expand $ExpandFile"
        #=================================================
    }
}
