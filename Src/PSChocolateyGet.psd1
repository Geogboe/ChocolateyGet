@{
RootModule = 'PSChocolateyGet.psm1'
ModuleVersion = '0.0.0'
GUID = '37c46e1a-5c01-4ad8-8f45-210d0155171d'
Author = 'George Bowen'
Copyright = '(c) George Bowen. All rights reserved.'
Description = 'Build Chocolatey packages programatically using a single configuration file which follows the winget schema'
PowerShellVersion = '7.0.0' # We need powershell 7 to do the schema validation stuff
# RequiredModules = @()
FunctionsToExport = "*"
# ModuleList = @()
# FileList = @()
PrivateData = @{
    PSData = @{
        Tags = @(
            "chocolatey", "winget", "validation", "packages"
        )
        # LicenseUri = ''
        ProjectUri = 'https://github.com/Geogboe/PSChocolateyGet'
        # IconUri = ''
        ReleaseNotes = ''
        # Prerelease = ''
        # ExternalModuleDependencies = @()
    }
}
# HelpInfoURI = ''
# DefaultCommandPrefix = ''
}
