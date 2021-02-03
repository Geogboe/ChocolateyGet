$ScriptDirectories = @{
    Public  = Join-Path $PSScriptRoot "public"
    Private = Join-Path $PSScriptRoot "private"
    Models  = Join-Path $PSScriptRoot "models"
}

if ( Test-Path $ScriptDirectories.Public ) {
    Get-ChildItem "$($ScriptDirectories.Public)\*.ps1" -Recurse  | ForEach-Object {
        . $_.FullName
    }
}

if ( Test-Path $ScriptDirectories.Private ) {
    Get-ChildItem "$($ScriptDirectories.Private)\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName
    }
}

if ( Test-Path $ScriptDirectories.Models ) {
    Get-ChildItem "$($ScriptDirectories.Models)\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName
    }
}

Export-ModuleMember -Function "*"