# Copyright 2021-2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

$ErrorActionPreference = 'Stop';

If ($args[0]) {""} Else { Write-Error "TCE version argument empty. Example usage: ./hack/choco/test/choco-upgrade-test.ps1 v0.10.0" }
$version = $args[0]

$parentDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$TCE_REPO = "https://github.com/vmware-tanzu/community-edition" 
$TCE_REPO_RELEASES_URL = "https://github.com/vmware-tanzu/community-edition/releases"
$TCE_WINDOWS_TAR_BALL_FILE = "tce-darwin-amd64-${version}.tar.gz"
$TCE_CHECKSUMS_FILE = "tce-checksums.txt"

Write-Host "${parentDir}" -ForegroundColor Cyan

#& "${parentDir}\test\e2e-test.ps1"

invoke-webrequest "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_WINDOWS_TAR_BALL_FILE}" -DisableKeepAlive -UseBasicParsing -Method head
invoke-webrequest "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_CHECKSUMS_FILE}" -DisableKeepAlive -UseBasicParsing -Method head


# Updating the version in tanzu-community-edition-temp.nuspec file
$text = Get-Content .\hack\choco\tanzu-community-edition.nuspec -Raw 
New-Item -Path "${parentDir}\.."  -Name "tanzu-community-edition-temp.nuspec" -ItemType "file" -Value $text
$Regex = [Regex]::new("(?<=<version>)(.*)(?=<\/version>)")
$oldVersion = $Regex.Match($text)
$text = $text.Replace( $oldVersion.value  , $version )
Set-Content -Path .\hack\choco\tanzu-community-edition.nuspec -Value $text

# Updating the version in chocolateyinstall.ps1 file
$text = Get-Content .\hack\choco\tools\chocolateyinstall.ps1 -Raw 
New-Item -Path "${parentDir}\..\tools"  -Name "chocolateyinstall-temp.ps1" -ItemType "file" -Value $text
$Regex = [Regex]::new("(?<=releaseVersion = ')(.*)(?=')")
$oldVersion = $Regex.Match($text)
$text = $text.Replace( $oldVersion.value  , $version )
Set-Content -Path .\hack\choco\tools\chocolateyinstall.ps1 -Value $text

