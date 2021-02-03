$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\..\..\Src\PSChocolateyGet.psd1 -Force

# Create a new chocolatey package based ont he spec
New-ChocolateyGetPackage -ConfigurationFile $PSScriptRoot\win-acme.yml -OutputDirectory $PSScriptRoot\_temp
