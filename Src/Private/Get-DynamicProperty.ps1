function Get-DynamicProperty {

    <#
    .SYNOPSIS
        Invokes a script to retrieve a property value in a package yml configuration
    .DESCRIPTION
        For instance, if you want to have the 'version' of the package always be latest,
        you can put the path to a script in the 'version' field instead of a static version
        and that script will be run and should return the latest version
    #>

    [CmdletBinding( PositionalBinding )]
    param (

        # Path to a script to run. Can be relative to the current
        # Working directory or fully qualified
        [Parameter( Mandatory )]
        [ValidateScript({
            if ( -not ( Test-Path $_ )) {
                throw "Unable to validate path: $_"
            }
            return $true
        })]
        [string]
        $Path

    )

    $ErrorActionPreference = "Stop"

    $FullPath = ( Resolve-Path $Path ).Path
    $StartJobArgs = @{
        # We use a scriptblock rather than file path as this allows using to use variables like $PSScriptRoot in our script
        # as well as set cert other properties
        ScriptBlock = {
            $VerbosePreference     = 0
            $DebugPreference       = 0
            $ProgressPreference    = 0
            $ErrorActionPreference = 'Stop'
            . $using:FullPath
        }
    }

    try {
        Write-Debug "Invoking dynamic script at path: $FullPath..."
        Start-Job @StartJobArgs | Receive-Job -Wait -AutoRemoveJob -Force
    }
    catch {
        Write-Warning "Dynamic script: $FullPath failed with the following exception:"
        throw $_
    }

}