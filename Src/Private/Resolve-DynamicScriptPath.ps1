function Resolve-DynamicScriptPath {

    <#
    .SYNOPSIS
        Determines to the full path to a script who'se provided path
        is relative to a given directory
    #>

    [CmdletBinding( PositionalBinding )]
    param (

        # Path to the script
        [Parameter( Mandatory )]
        [string]
        $Path,

        # A relative path to use to resolve the full path
        [string]
        $RelativePath

    )

    $ErrorActionPreference = "Stop"

    if ( [System.IO.Path]::IsPathFullyQualified( $Path )) {
        Write-Debug "Path: $Path is already fully qualified."
        return $Path
    }

    if ( -not $RelativePath ) {
        throw "NO relative path provided. Unable to determine fully qualified path to: $Path."
    }

    $FullRelativePath = ( Resolve-Path $RelativePath ).Path

    # If no file extension, assume this is a directory, otherwise get the parent directory
    if ( -not [System.IO.Path]::HasExtension( $FullRelativePath )) {
        $ParentDirPath = $FullRelativePath
    }
    else {
        $ParentDirPath = ( Split-Path -Parent $FullRelativePath )
    }

    return ( Join-Path $ParentDirPath $Path )

}