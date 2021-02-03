# ./.depend.psd1
# https://github.com/RamblingCookieMonster/PSDepend
@{
    Pester           = 'latest'
    BuildHelpers     = 'latest '
    PSDeploy         = 'latest'
    PSScriptAnalyzer = "latest"
    InvokeBuild      = "latest"
    'git in PATH'    = @{
        DependencyType = 'Command'
        Source         = '
            if ( -not ( Get-Command git -ea 0 )) {
                throw "Git is not available in PATH. Please install git and add it to your path."
            }
        '
        FailOnError    = $true
    }
}