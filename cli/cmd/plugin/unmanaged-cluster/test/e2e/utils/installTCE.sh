#!/bin/bash

# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

wget  https://github.com/vmware-tanzu/community-edition/releases/download/v0.11.0/tce-darwin-amd64-v0.11.0.tar.gz

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
tar -xf "${MY_DIR}"/../tce-darwin-amd64-v0.11.0.tar.gz
rm -f "${MY_DIR}"/../tce-darwin-amd64-v0.11.0.tar.gz

cd tce-darwin-amd64-v0.11.0

# TCE installation
./install.sh
