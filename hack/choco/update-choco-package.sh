#!/bin/bash
 
# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
 
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace
 
version="${1:?TCE version argument empty. Example usage: ./hack/choco/update-choco-package.sh v0.10.0}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"
 
temp_dir=$(mktemp -d)
MY_DIR="$(git rev-parse --show-toplevel)"
 
pushd "${temp_dir}"

TCE_REPO="https://github.com/vmware-tanzu/community-edition" 
TCE_REPO_RELEASES_URL="https://github.com/vmware-tanzu/community-edition/releases"
TCE_DARWIN_TAR_BALL_FILE="tce-darwin-amd64-${version}.tar.gz"
TCE_LINUX_TAR_BALL_FILE="tce-linux-amd64-${version}.tar.gz"
TCE_CHECKSUMS_FILE="tce-checksums.txt"
TCE_CHOCO_TAP_REPO="https://github.com/vmware-tanzu/community-edition/hack/choco"
 
echo "Checking if the necessary files exist for the TCE ${version} release"
 
curl -f -I -L \
   "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_DARWIN_TAR_BALL_FILE}" > /dev/null || {
       echo "${TCE_DARWIN_TAR_BALL_FILE} is not accessible in TCE ${version} release"
       exit 1
   }
 
curl -f -I -L \
   "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_LINUX_TAR_BALL_FILE}" > /dev/null || {
       echo "${TCE_LINUX_TAR_BALL_FILE} is not accessible in TCE ${version} release"
       exit 1
   }
 
wget "${TCE_REPO_RELEASES_URL}/download/${version}/${TCE_CHECKSUMS_FILE}" || {
   echo "${TCE_CHECKSUMS_FILE} is not accessible in TCE ${version} release"
   exit 1
}
 
git clone "${TCE_REPO}"

cd community-edition

# make sure we are on main branch before checking out
git checkout main
 
PR_BRANCH="update-tce-to-${version}-${RANDOM}"
 
# Random number in branch name in case there's already some branch for the version update,
# though there shouldn't be one. There could be one if the other branch's PR tests failed and didn't merge
git checkout -b "${PR_BRANCH}"
 
# Replacing old version with the latest stable released version.
# Using -i so that it works on Mac and Linux OS, so that it's useful for local development.
sed -i -e 's/\($releaseVersion =\).*/$releaseVersion ='"'${version}'"'/g' "${MY_DIR}"/hack/choco/tools/chocolateyinstall.ps1
rm -fv "${MY_DIR}"/hack/choco/tools/chocolateyinstall.ps1-e
 
version="${version:1}"
sed -i -e 's/\(<version>\).*\(<\/version>\)/<version>'"${version}"'\<\/version>/g' "${MY_DIR}"/hack/choco/tanzu-community-edition.nuspec
rm -fv "${MY_DIR}"/hack/choco/tanzu-community-edition.nuspec-e
 
 
git add "${MY_DIR}"/hack/choco/tools/chocolateyinstall.ps1
git add "${MY_DIR}"/hack/choco/tanzu-community-edition.nuspec
 
git commit -m "auto-generated - update tce choco install scripts for version ${version}"
 
git push origin "${PR_BRANCH}"
 
gh pr create --repo ${TCE_CHOCO_TAP_REPO} --title "auto-generated - update tce choco install scripts for version ${version}" --body "auto-generated - update tce choco install scripts for version ${version}"
 
gh pr merge --repo ${TCE_CHOCO_TAP_REPO} "${PR_BRANCH}" --squash --delete-branch --auto
 
popd
