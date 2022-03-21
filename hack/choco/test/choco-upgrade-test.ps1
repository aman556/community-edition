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
 
Push-Location $temp_dir

$TCE_REPO = "git@github.com:aman556/community-edition.git"
$TCE_REPO_RELEASES_URL = "https://github.com/vmware-tanzu/community-edition/releases"
$TCE_WINDOWS_ZIP_FILE="tce-windows-amd64-${version}.zip"
$TCE_CHECKSUMS_FILE = "tce-checksums.txt"



New-Item -Path 'id_ed25519' -ItemType File

Set-Content -Path id_ed25519 -Value $env:key

#Write-Host $key
#Get-Content -Path id_ed25519

Get-Location

# By default the ssh-agent service is disabled. Allow it to be manually started for the next step to work.
Get-Service ssh-agent | Set-Service -StartupType Manual

# Start the service
start ssh-agent

# This should return a status of Running
#Get-Service ssh-agent

ssh-add .\id_ed25519

# Now load your key files into ssh-agent


# Use --depth 1 once https://github.com/cli/cli/issues/2979#issuecomment-780490392 get resolve
git clone $TCE_REPO

cd community-edition/hack/choco

$RANDOM = Get-Random
$PR_BRANCH = "update-tce-to-$version-$RANDOM"
 
# Random number in branch name in case there's already some branch for the version update,
# though there shouldn't be one. There could be one if the other branch's PR tests failed and 
# didn't merge then we are adding another random value for that but as we are testing the brew 
# formula so no PR will raise if it fails.
$DOES_NEW_BRANCH_EXIST=$(git branch -a | Select-String "remotes" | Select-String "${PR_BRANCH}" )
Write-Host "does branch exist: ${DOES_NEW_BRANCH_EXIST}"
if ( "${DOES_NEW_BRANCH_EXIST}" -eq "" ) {
    git checkout -b "${PR_BRANCH}"
}
else {
    $RANDOM = Get-Random
    PR_BRANCH="${PR_BRANCH}-${RANDOM}"
    git checkout -b "${PR_BRANCH}"
}

# setup
git config user.name aman556
git config user.email amansharma14041998@gmail.com

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

git push origin $PR_BRANCH
 
gh pr create --repo ${TCE_REPO} --title "auto-generated - update tce choco install scripts for version $version" --body "auto-generated - update tce choco install scripts for version ${version}"
 
gh pr merge --repo $TCE_REPO $PR_BRANCH --squash --delete-branch --admin
 
Pop-Location $temp_dir
