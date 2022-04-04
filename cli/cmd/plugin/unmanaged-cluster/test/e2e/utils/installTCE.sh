#!/bin/bash

# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x


wget  https://github.com/vmware-tanzu/community-edition/releases/download/v0.11.0/tce-linux-amd64-v0.11.0.tar.gz

#MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TCE_REPO_PATH="$(git rev-parse --show-toplevel)"
E2E_REPO_PATH="${TCE_REPO_PATH}/cli/cmd/plugin/unmanaged-cluster/test/e2e"
ls
tar -xf "${E2E_REPO_PATH}"/tce-linux-amd64-v0.11.0.tar.gz
rm -f "${E2E_REPO_PATH}"/tce-linux-amd64-v0.11.0.tar.gz

ls
"${E2E_REPO_PATH}"/utils/install-dependencies.sh
cd tce-linux-amd64-v0.11.0


# TCE installation
./install.sh
