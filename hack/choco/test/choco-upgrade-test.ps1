# Copyright 2021-2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

param (
    # TCE release version argument
    [Parameter(Mandatory=$True)]
    [string]$version
)

$ErrorActionPreference = 'Stop';

if ((Test-Path env:GITHUB_TOKEN) -eq $False) {
  throw "GITHUB_TOKEN environment variable is not set"
}

$temp_dir = Join-Path $Env:Temp $(New-Guid); New-Item -Type Directory -Path $temp_dir | Out-Null
 
Push-Location "${temp_dir}"

$TCE_REPO = "https://github.com/aman556/community-edition" 
$TCE_REPO_RELEASES_URL = "https://github.com/vmware-tanzu/community-edition/releases"
$TCE_WINDOWS_ZIP_FILE="tce-windows-amd64-${version}.zip"
$TCE_CHECKSUMS_FILE = "tce-checksums.txt"


# Use --depth 1 once https://github.com/cli/cli/issues/2979#issuecomment-780490392 get resolve
git clone "${TCE_REPO}"

cd community-edition/hack/choco
$RANDOM = Get-Random
$PR_BRANCH = "update-tce-to-${version}-${RANDOM}"
 
# Random number in branch name in case there's already some branch for the version update,
# though there shouldn't be one. There could be one if the other branch's PR tests failed and didn't merge
git checkout -b "${PR_BRANCH}"

# setup
git config --global --replace-all user.name "aman556"
git config --global --replace-all user.email "amansharma14041998@gmail.com"

Write-Host "Git user updated" -foregroundcolor blue
            
Write-Host "user.name: " -foregroundcolor blue -nonewline
git config --global user.name
        
Write-Host "user.email: " -foregroundcolor blue -nonewline
git config --global user.email   

Write-Host "Git user updated" -foregroundcolor blue
            
Write-Host "user.name: " -foregroundcolor blue -nonewline
git config user.name
        
Write-Host "user.email: " -foregroundcolor blue -nonewline
git config user.email   

# Testing for current release
& test\e2e-test.ps1

Write-Host "Checking if the necessary files exist for the TCE $version release"

invoke-webrequest "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_WINDOWS_ZIP_FILE}" -DisableKeepAlive -UseBasicParsing -Method head
invoke-webrequest "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_CHECKSUMS_FILE}" -OutFile test/tce-checksums.txt

$Checksum64 = ((Select-String -Path "./test/tce-checksums.txt" -Pattern "tce-windows-amd64-${version}.zip").Line.Split(" "))[0]

# Updating the version in tanzu-community-edition-temp.nuspec file
$textnuspec = Get-Content .\tanzu-community-edition.nuspec -Raw
$temptextnuspec = Get-Content .\tanzu-community-edition.nuspec -Raw 
$Regex = [Regex]::new("(?<=<version>)(.*)(?=<\/version>)")
$oldVersion = $Regex.Match($textnuspec)
$textnuspec = $textnuspec.Replace( $oldVersion.value  , $version.Substring(1) )
Set-Content -Path .\tanzu-community-edition.nuspec -Value $textnuspec


# Updating the version in chocolateyinstall.ps1 file
$textchocoinstall = Get-Content .\tools\chocolateyinstall.ps1 -Raw 
$temptextchocoinstall = Get-Content .\tools\chocolateyinstall.ps1 -Raw 
$Regex = [Regex]::new("(?<=releaseVersion = ')(.*)(?=')")
$oldVersion = $Regex.Match($textchocoinstall)
$textchocoinstall = $textchocoinstall.Replace( $oldVersion.value  , $version )

# Updating the Checksum64 in chocolateyinstall.ps1 file
$Regex = [Regex]::new("(?<=checksum64 = ')(.*)(?=')")
$oldChecksum64 = $Regex.Match($textchocoinstall)
$textchocoinstall = $textchocoinstall.Replace( $oldChecksum64.value  , $Checksum64 )

Set-Content -Path .\tools\chocolateyinstall.ps1 -Value $textchocoinstall

# Testing for latest release
& test\e2e-test.ps1


Remove-Item test/tce-checksums.txt

git add tools/chocolateyinstall.ps1
git add tanzu-community-edition.nuspec
 
git commit -s -m "auto-generated - update tce choco install scripts for version ${version}"
 
Write-Host "Git user updated" -foregroundcolor blue
            
Write-Host "user.name: " -foregroundcolor blue -nonewline
git config --global user.name
        
Write-Host "user.email: " -foregroundcolor blue -nonewline
git config --global user.email   

Write-Host "Git user updated" -foregroundcolor blue
            
Write-Host "user.name: " -foregroundcolor blue -nonewline
git config user.name
        
Write-Host "user.email: " -foregroundcolor blue -nonewline
git config user.email   

git push origin "${PR_BRANCH}"
 
gh pr create --repo ${TCE_REPO} --title "auto-generated - update tce choco install scripts for version ${version}" --body "auto-generated - update tce choco install scripts for version ${version}"
 
gh pr merge --repo ${TCE_REPO} "${PR_BRANCH}" --squash --delete-branch --auto
 
Pop-Location "${temp_dir}"
