# Copyright 2021-2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

$ErrorActionPreference = 'Stop';

$parentDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Write-Host "${parentDir}" -ForegroundColor Cyan

#& "${parentDir}\e2e-test.ps1"

invoke-webrequest https://github.com/vmware-tanzu/community-edition/releases/download/v0.10.0-rc.4/tce-windows-amd64-v0.10.0-rc.4.zip -DisableKeepAlive -UseBasicParsing -Method head
    

#if ( $result.StatusCode -ne 200 )
#    { Write-Host "Not Accesible" }
