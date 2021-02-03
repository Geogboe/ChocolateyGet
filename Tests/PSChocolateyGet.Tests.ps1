Describe "PSChocolateyGet Module" {
    It "Imports successfully" {
        { Import-Module $PSScriptRoot\..\Src\PSChocolateyGet.psd1 -Force } | Should -Not -Throw
    }
}