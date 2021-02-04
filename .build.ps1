using module BuildHelpers
using module Pester
using module PSScriptAnalyzer
using module PSDeploy

$ModuleName = ( Split-Path ( Resolve-Path "$PSScriptRoot\Src\*.psd1" ).Path -Leaf ) -replace "\.psd1"
$ModuleData = Import-PowerShellDataFile -Path "$PSScriptRoot\Src\$ModuleName.psd1"
$ModuleVersion = [version](( & git tag --list --sort="-v:refname" | Select-Object -First 1 ).Trim('v'))
$OutputDirectory = "$PSScriptRoot\.build\$ModuleName\$ModuleVersion"

Task * Init, Build, Format, Docs

Task Init {
    if ( Test-Path $PSScriptRoot\.build ) {
        Remove-Item $PSScriptRoot\.build -Force -Recurse
    }
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    New-Item -Path $OutputDirectory\Docs -ItemType Directory -Force | Out-Null
}

Task Test {
    $Result = Invoke-Pester -Path $PSScriptRoot\Tests -Output Detailed -PassThru
    if ( $Result.Failed -gt 0 ) {
        throw "Tests failed"
    }
}

Task Build Init, {

    Copy-Item $PSScriptRoot\Src\*.psd1 $OutputDirectory -Force
    Update-Metadata -Path "$OutputDirectory\$ModuleName.psd1" -PropertyName "ModuleVersion" -Value $ModuleVersion

    if ( Test-Path $PSScriptRoot\Src\Models\*.psm1 ) {
        Get-ChildItem $PSScriptRoot\Src\Models\*.psm1 -Recurse | ForEach-Object {
            ( Get-Content $_.FullName ) -replace "^using.*." | Add-Content $OutputDirectory\$ModuleName.psm1 -Force -Encoding utf8
        }
    }

    $PublicFunctions = @()
    if ( Test-Path $PSScriptRoot\Src\Public\*.ps1 ) {
        Get-ChildItem $PSScriptRoot\Src\Public\*.ps1 -Recurse | ForEach-Object {
            ( Get-Content $_.FullName ) -replace "^using.*." | Add-Content $OutputDirectory\$ModuleName.psm1 -Force -Encoding utf8
            $PublicFunctions += $_.BaseName
        }
    }

    if ( $PublicFunctions ) {
        Update-Metadata -Path "$OutputDirectory\$ModuleName.psd1" -PropertyName "FunctionsToExport" -Value $PublicFunctions
    }

    if ( Test-Path $PSScriptRoot\Src\Assets\* ) {
        Copy-Item $PSScriptRoot\Src\Assets -Destination $OutputDirectory\ -Force -Recurse
    }

    if ( Test-Path $PSScriptRoot\Src\Localized\en-US\* ) {
        Copy-Item $PSScriptRoot\Src\Localized\en-US\ -Destination $OutputDirectory\ -Force -Recurse
    }

    if ( Test-Path $PSScriptRoot\Src\Private\*.ps1 ) {
        Get-ChildItem $PSScriptRoot\Src\Private\*.ps1 -Recurse | ForEach-Object {
            ( Get-Content $_.FullName ) -replace "^using.*." | Add-Content $OutputDirectory\$ModuleName.psm1 -Force -Encoding utf8
        }
    }

    if ( Test-Path $PSScriptRoot\Src\Public\*.ps1 ) {
        Get-ChildItem $PSScriptRoot\Src\Public\*.ps1 -Recurse | ForEach-Object {
            ( Get-Content $_.FullName ) -replace "^using.*." | Add-Content $OutputDirectory\$ModuleName.psm1 -Force -Encoding utf8
        }
    }

    # Add release notes to content
    $ReleaseNotes = @()
    $Tags = & git tag --list --sort="-v:refname"
    for ( $i = 0; $i -lt $Tags.Count - 1; $i++ ) {
        $TagName = $Tags[$i]
        $TagDate = [datetime]( & git show "$TagName" -q --format="%ci" | Select-Object -Last 1 )
        $PreviousTag = $Tags[$i + 1]
        $ReleaseNotes += "$TagName [$($TagDate.ToLongDateString()) $($TagDate.ToShortTimeString())]"
        $ReleaseNotes += & git shortlog "$PreviousTag..$TagName" --no-merges --format="* [%h] %s"
    }
    $ReleaseNotes = $ModuleData.PrivateData.PSData.ReleaseNotes + $ReleaseNotes
    Update-Metadata -Path "$OutputDirectory\$ModuleName.psd1" -PropertyName "PrivateData.PSData.ReleaseNotes" -Value $ReleaseNotes

}

Task Format {
    Invoke-ScriptAnalyzer -Path $OutputDirectory -Recurse -ReportSummary -Settings CodeFormatting
}

Task Docs {
    # Run this in a new process as it collids with other loaded libraries sometimes
    Start-Job {
        Import-Module PlatyPS
        Import-Module "$using:OutputDirectory\$using:ModuleName.psd1" -Force
        New-MarkdownHelp -ModuleName "PSChocolateyGet" -OutputFolder $using:OutputDirectory\Docs
    } | Receive-Job -Wait -AutoRemoveJob -Force
}

Task Publish {
    Invoke-PSDeploy -Path $PSScriptRoot\.psdeploy.ps1
}

Task Cleanup {
    Remove-Item $PSScriptRoot\.build -Force -Recurse
}