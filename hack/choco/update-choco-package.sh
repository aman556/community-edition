#!/bin/bash
 
# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
 
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace
 
version="${1:?TCE version argument empty. Example usage: ./hack/choco/update-choco-package.sh v0.10.0}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"
 
 
temp_dir=$(mktemp -d)
 
pushd "${temp_dir}"

TCE_REPO="https://github.com/aman556/community-edition" 
TCE_REPO_RELEASES_URL="https://github.com/vmware-tanzu/community-edition/releases"
TCE_WINDOWS_TAR_BALL_FILE="tce-darwin-amd64-${version}.tar.gz"
TCE_CHECKSUMS_FILE="tce-checksums.txt"
 
echo "Checking if the necessary files exist for the TCE ${version} release"
 
wget --spider -q \
   "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_WINDOWS_TAR_BALL_FILE}" || {
       echo "${TCE_WINDOWS_TAR_BALL_FILE} is not accessible in TCE ${version} release"
       exit 1
   }
 
wget --spider -q "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_CHECKSUMS_FILE}" || {
   echo "${TCE_CHECKSUMS_FILE} is not accessible in TCE ${version} release"
   exit 1
}
 
git clone --depth 1 "${TCE_REPO}"

cd community-edition
 
PR_BRANCH="update-tce-to-${version}-${RANDOM}"
 
# Random number in branch name in case there's already some branch for the version update,
# though there shouldn't be one. There could be one if the other branch's PR tests failed and didn't merge
git checkout -b "${PR_BRANCH}"

# Handle differences in MacOS sed
SEDARGS=""
if [ "$(uname -s)" = "Darwin" ]; then
    SEDARGS="-i.bak"
fi

# Replacing old version with the latest stable released version.
sed $SEDARGS "s/\(\$releaseVersion =\).*/\$releaseVersion = ""'${version}'""/g" hack/choco/tools/chocolateyinstall.ps1 
rm -fv hack/choco/tools/chocolateyinstall.ps1.bak

version="${version:1}"
sed $SEDARGS "s/\(<version>\).*\(<\/version>\)/<version>""${version}""\<\/version>/g" hack/choco/tanzu-community-edition.nuspec
rm -fv hack/choco/tanzu-community-edition.nuspec.bak
 
git add hack/choco/tools/chocolateyinstall.ps1
git add hack/choco/tanzu-community-edition.nuspec
 
git commit -m "auto-generated - update tce choco install scripts for version ${version}"
 
git push origin "${PR_BRANCH}"
 
gh pr create --repo ${TCE_REPO} --title "auto-generated - update tce choco install scripts for version ${version}" --body "auto-generated - update tce choco install scripts for version ${version}"
 
gh pr merge --repo ${TCE_REPO} "${PR_BRANCH}" --squash --delete-branch --auto
 
popd
