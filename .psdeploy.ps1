# ./.psdeploy.ps1
# https://psdeploy.readthedocs.io/en/latest
Deploy PSChocolateyGet {
    By PSGalleryModule {
        FromSource "$PSScriptRoot\.build\PSChocolateyGet"
        To "psgallery"
        WithOptions @{
            ApiKey = ( Get-Secret -AsPlainText psgallery_api_key )
        }
        Tagged "production"
    }
}