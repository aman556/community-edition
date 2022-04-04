#!/bin/bash

# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

cd tce-darwin-amd64-v0.11.0
# TCE uninstallation
./uninstall.sh

cd ..
rm -rf tce-linux-amd64-v0.11.0
