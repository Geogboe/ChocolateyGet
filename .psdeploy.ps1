# ./.psdeploy.ps1
# https://psdeploy.readthedocs.io/en/latest
Deploy PSChocolateyGet {
    By PSGalleryModule {
        FromSource "$PSScriptRoot\.build\PSChocolateyGet"
        To "$env:PS_MODULE_REPO_NAME"
        WithOptions @{
            ApiKey = $env:PS_MODULE_REPO_API_KEY
        }
        Tagged "production"
    }
}