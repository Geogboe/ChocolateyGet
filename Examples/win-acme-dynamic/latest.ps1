$PackageSource = "https://api.github.com/repos/win-acme/win-acme/releases/latest"
$LatestRelease = Invoke-RestMethod -Uri $PackageSource -UseBasicParsing
$DownloadUrl = $LatestRelease.assets.Where( { $_.Name -match "x64.pluggable.zip" }).browser_download_url
$FileName = Split-Path $DownloadUrl -Leaf
$DownloadPath = Join-Path TEMP:\ $FileName

if ( -not ( Test-Path $DownloadPath )) {
    $ProgressPreference = 0; Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing -OutFile $DownloadPath
}

return @{
    Name         = 'win-acme'
    Version      = $LatestRelease.tag_name.Trim("v")
    ReleaseNotes = $LatestRelease.body
    Url          = $DownloadUrl
    Sha256       = ( Get-FileHash -Path $DownloadPath -Algorithm SHA256 ).Hash
}
