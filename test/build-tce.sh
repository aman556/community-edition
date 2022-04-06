#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This script clones TCE repo and builds the latest release

set -x
set -e

TCE_REPO_PATH="$(git rev-parse --show-toplevel)"
# shellcheck source=test/util/utils.sh
source "${TCE_REPO_PATH}/test/util/utils.sh"

BUILD_OS=$(uname -s)
export BUILD_OS

# Build TCE
echo "Building TCE release..."
make release || { error "TCE BUILD FAILED!"; exit 1; }
echo "Installing TCE release"
if [[ $BUILD_OS == "Linux" ]]; then
    pushd release/tce-linux-amd64*/ || exit 1
elif [[ $BUILD_OS == "Darwin" ]]; then
    if [[ "$BUILD_ARCH" == "x86_64" ]]; then
        pushd release/tce-darwin-amd64*/ || exit 1
    else
        pushd release/tce-darwin-arm64*/ || exit 1
    fi
fi
./uninstall.sh || { error "TCE CLEANUP (UNINSTALLATION) FAILED!"; exit 1; }

mkdir -p /home/ubuntu/.config/tanzu/tkg/unmanaged/compatibility

echo 'version: v1
unmanagedClusterPluginVersions:
- version: v0.12.0-dev.1
  supportedTkrVersions:
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0-dev-2
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0-dev-1
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0
  - image: projects.registry.vmware.com/tce/tkr:v1.22.5
- version: dev
  supportedTkrVersions:
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0-dev-2
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0-dev-1
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0
  - image: projects.registry.vmware.com/tce/tkr:v1.22.5
- version: v0.11.0
  supportedTkrVersions:
  - image: projects.registry.vmware.com/tce/tkr:v0.17.0
  - image: projects.registry.vmware.com/tce/tkr:v1.22.5
- version: v0.10.0
  supportedTkrVersions:
  - image: projects.registry.vmware.com/tce/tkr:v0.21.5' > /home/ubuntu/.config/tanzu/tkg/unmanaged/compatibility/projects.registry.vmware.com_tce_compatibility_v4


echo "abcd"

./install.sh || { error "TCE INSTALLATION FAILED!"; exit 1; }
popd || exit 1
echo "TCE version..."
tanzu management-cluster version || { error "Unexpected failure during TCE installation"; exit 1; }
