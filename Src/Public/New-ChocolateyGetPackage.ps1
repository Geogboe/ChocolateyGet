function New-ChocolateyGetPackage {

    <#
    .SYNOPSIS
        Creates a new chocolatey package based on a configuration file
    #>

    [CmdletBinding( PositionalBinding )]
    param (

        # Path to a configuration file
        [Parameter( Mandatory )]
        [ValidateScript( {
                if ( -not ( Test-Path $_ )) {
                    throw "Unable to validate path: $_"
                }
                return $true
            })]
        [string]
        $ConfigurationFile,

        # Path to a directory where the package will be built.
        # By defaul tthi swill be the current working directory
        # If the directory doesn't exist, it will be created.
        [string]
        $OutputDirectory = $PWD

    )

    $ErrorActionPreference = "Stop"

    if ( -not ( Test-Path $OutputDirectory )) {
        Write-Debug "Creating local directory at path: $OutputDirectory..."
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }

    # TODO - validate schema
    $PackageConfig = [PSCustomObject]( Get-Content $ConfigurationFile | ConvertFrom-Yaml )

    if ( $PackageConfig.Version -match ".*.\.ps1" ) {
        $DynamicScriptPath = $PackageConfig.Version
        Write-Debug "Retrieving version of package using dynamic script: $DynamicScriptPath..."
        $PackageVersion = ( Get-DynamicProperty -Path $DynamicScriptPath ).Version
    }
    else {
        $PackageVersion = $PackageConfig.Version
    }

    $PackageDirName = $PackageConfig.AppMoniker + "." + $PackageVersion
    $PackageOutputDir = Join-Path $OutputDirectory $PackageDirName
    $PackageToolsDir = Join-Path $PackageOutputDir "tools"

    if ( -not ( Test-Path $PackageOutputDir )) {
        Write-Debug "Creating local directory at path: $PackageOutputDir..."
        New-Item -Path $PackageOutputDir -ItemType Directory -Force | Out-Null
    }

    if ( -not ( Test-Path $PackageToolsDir )) {
        Write-Debug "Creating local directory at path: $PackageToolsDir..."
        New-Item -Path $PackageToolsDir -ItemType Directory -Force | Out-Null
    }

    $PackageNuspecFileName = $PackageConfig.AppMoniker + ".nuspec"
    $PackageNuspecPath = Join-Path $PackageOutputDir $PackageNuspecFileName
    $PackageSummary = $PackageConfig.Description -split "`n" | Select-Object -First 1
    $PackageNuspecConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
<metadata>
    <id>$($PackageConfig.AppMoniker)</id>
    <version>$($PackageVersion)</version>
    <owners>$($PackageConfig.Publisher)</owners>
    <title>$($PackageConfig.Name)(Install)</title>
    <authors>$($PackageConfig.Author)</authors>
    <projectUrl>$($PackageConfig.Homepage)</projectUrl>
    <copyright>$( Get-Date -Format yyyy ) $($PackageConfig.Author)</copyright>
    <licenseUrl>$($PackageConfig.LicenseUrl)</licenseUrl>
    <tags>$($PackageConfig.Tags -replace ",")</tags>
    <summary>$PackageSummary</summary>
    <description>
$(($PackageConfig.Description).Trim())
    </description>
    <dependencies>
      <dependency id="chocolatey-core.extension" version="1.1.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@

    $NuspecOutdated = $true
    if ( Test-Path $PackageNuspecPath ) {
        $PackageNuspecContent = Get-Content $PackageNuspecPath
        $NuspecOutdated = [bool]( Compare-Object $PackageNuspecContent $PackageNuspecConfig )
    }

    # Update nuspec file if it isn't what it should be
    if ( $NuspecOutdated ) {
        ( [xml]$PackageNuspecConfig ).Save( $PackageNuspecPath )
    }

    $ChocolateyInstallScriptPath = Join-Path $PackageOutputDir "tools\chocolateyinstall.ps1"
    $ChocolateyUninstallScriptPath = Join-Path $PackageOutputDir "tools\chocolateyuninstall.ps1"
    $ChocolateyBeforeModifyScriptPath = Join-Path $PackageOutputDir "tools\chocolateybeforemodify.ps1"
    $ChocolateyInstallScriptContent = @()
    $ChocolateyUninstallScriptContent = @()
    $ChocolateyBeforeModifyScriptContent = @()

    # If the installer type is zip, add script to install zip file
    if ( $PackageConfig.InstallerType -eq 'zip' ) {

        $InstallDirectory = '$env:ProgramFiles\' + $PackageConfig.Name

        foreach ( $Installer in $PackageConfig.Installers ) {

            $Arch = switch ( $Installer.Arch ) {
                "x64" { @{ Url = "url64"; Checksum = "checksum64"; ChecksumType = "checksumtype64" } }
                "x86" { @{ Url = "url"; Checksum = "checksum"; ChecksumType = "checksumtype" } }
            }

            # Get the installer url if its a dynamic value
            if ( $Installer.Url -match ".*.\.ps1" ) {
                $DynamicScriptPath = $Installer.Url
                Write-Debug "Retrieving url of installer using dynamic script: $DynamicScriptPath..."
                $Url = ( Get-DynamicProperty -Path $DynamicScriptPath ).Url
            }
            else {
                $Url = $Installer.Url
            }

            # Get the installer sha256 if its a dynamic value
            if ( $Installer.Sha256 -match ".*.\.ps1" ) {
                $DynamicScriptPath = $Installer.Sha256
                Write-Debug "Retrieving Sha256 of installer using dynamic script: $DynamicScriptPath..."
                $Sha256 = ( Get-DynamicProperty -Path $DynamicScriptPath ).Sha256
            }
            else {
                $Sha256 = $Installer.Sha256
            }

            # Add installation code
            $ChocoZipInstallCode = @"
`$ErrorActionPreference = 'Stop'
`$toolsDir   = "`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)"
`$packageArgs = @{
    packageName   = `$env:ChocolateyPackageName
    unzipLocation = "$InstallDirectory"
    fileType      = 'EXE_MSI_OR_MSU' #only one of these: exe, msi, msu
    $($Arch.Url)           = '$($Url)'
    $($Arch.Checksum)      = '$($Sha256)'
    $($Arch.ChecksumType)  = 'sha256'
}
Install-ChocolateyZipPackage @packageArgs

# Add bins to path
Get-ChildItem "$InstallDirectory\*.exe"  | ForEach-Object {
    Install-BinFile -name `$_.BaseName -path `$_.FullName
}
"@
            $ChocolateyInstallScriptContent += $ChocoZipInstallCode

            # Add before modify code
            $ChocoZipBeforeModifyCode = @"
Get-ChildItem "$InstallDirectory\*.exe"  | ForEach-Object {
    Uninstall-BinFile -name `$_.BaseName -path `$_.FullName
}
"@
            $ChocolateyBeforeModifyScriptContent += $ChocoZipBeforeModifyCode

            # Add uninstall code
            $ZipFileName = Split-Path $Url -Leaf
            $ChocoZipUninstallCode = @"
Uninstall-ChocolateyZipPackage -packageName `$env:ChocolateyPackageName -zipFileName '$ZipFileName'
"@

            $ChocolateyUninstallScriptContent += $ChocoZipUninstallCode
        }

    }

    # Write the chocolatey install scripts
    if ( $ChocolateyInstallScriptContent ) {
        $NeedsUpdate = $true
        $ScriptContent = $ChocolateyInstallScriptContent -join "`r`n"
        if ( Test-Path $ChocolateyInstallScriptPath ) {
            $ExistingScriptContent = Get-Content $ChocolateyInstallScriptPath
            $NeedsUpdate = [bool]( Compare-Object $ExistingScriptContent $ScriptContent )
        }

        if ( $NeedsUpdate ) {
            Set-Content -Path $ChocolateyInstallScriptPath -Value $ScriptContent -Force -Encoding utf8
        }
    }

    # Write the chocolatey uninstall scripts
    if ( $ChocolateyUninstallScriptContent ) {
        $NeedsUpdate = $true
        $ScriptContent = $ChocolateyUninstallScriptContent -join "`r`n"
        if ( Test-Path $ChocolateyUninstallScriptPath ) {
            $ExistingScriptContent = Get-Content $ChocolateyUninstallScriptPath
            $NeedsUpdate = [bool]( Compare-Object $ExistingScriptContent $ScriptContent )
        }

        if ( $NeedsUpdate ) {
            Set-Content -Path $ChocolateyUninstallScriptPath -Value $ScriptContent -Force -Encoding utf8
        }
    }

    # Write the chocolatey before modify script
    if ( $ChocolateyBeforeModifyScriptContent ) {
        $NeedsUpdate = $true
        $ScriptContent = $ChocolateyBeforeModifyScriptContent -join "`r`n"
        if ( Test-Path $ChocolateyBeforeModifyScriptPath ) {
            $ExistingScriptContent = Get-Content $ChocolateyBeforeModifyScriptPath
            $NeedsUpdate = [bool]( Compare-Object $ExistingScriptContent $ScriptContent )
        }

        if ( $NeedsUpdate ) {
            Set-Content -Path $ChocolateyBeforeModifyScriptPath -Value $ScriptContent -Force -Encoding utf8
        }
    }

    # Todo - msi installer
    # Todo - exe installer
    # Todo - appx installer
    # Todo - msix installer

    # Format code. For some reason you have to run this twice
    Write-Debug "Formatting code..."
    Invoke-ScriptAnalyzer -Path $PackageOutputDir -Recurse -Settings CodeFormatting -Fix | Out-Null
    Invoke-ScriptAnalyzer -Path $PackageOutputDir -Recurse -Settings CodeFormatting -Fix | Out-Null
}