#!/bin/bash

# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This script installs dependencies needed for running build-tce.sh

BUILD_OS=$(uname -s)
BUILD_ARCH=$(uname -m 2>/dev/null || echo Unknown)
export BUILD_OS

# Make sure docker is installed
echo "Checking for Docker..."
if [ -z "$(command -v docker)" ]; then
    echo "Installing Docker..."
    if [ "${BUILD_OS}" == "Linux" ]; then
        sudo apt-get update > /dev/null
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release > /dev/null 2>&1
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
            "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update > /dev/null
        sudo apt install -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
        sudo service docker start
        sleep 30s

        if [ "$(id -u)" -ne 0 ]; then
            sudo usermod -aG docker "$(whoami)"
        fi
    elif [ "${BUILD_OS}" == "Darwin" ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        brew install docker
        brew install docker-machine
        brew install virtualbox --cask
        docker-machine create --driver virtualbox default
        eval "$(docker-machine env default)"
    fi
else
    echo "Found Docker!"
fi

echo "Verifying Docker..."
if ! docker run --rm hello-world > /dev/null; then
    error "Unable to verify docker functionality, make sure docker is installed correctly"
    exit 1
else
    echo "Verified Docker functionality successfully!"
fi

# Make sure kubectl is installed
echo "Checking for kubectl..."
if [ -z "$(command -v kubectl)" ]; then
    echo "Installing kubectl..."
    if [ "${BUILD_OS}" == "Linux" ]; then
        curl -LO https://dl.k8s.io/release/v1.20.1/bin/linux/amd64/kubectl
    elif [ "${BUILD_OS}" == "Darwin" ]; then
        if [ "${BUILD_ARCH}" == "x86_64" ]; then
            curl -LO https://dl.k8s.io/release/v1.20.1/bin/darwin/amd64/kubectl
        elif [ "${BUILD_ARCH}" == "arm64" ]; then
            curl -LO https://dl.k8s.io/release/v1.20.1/bin/darwin/arm64/kubectl
        else
            error "${BUILD_OS}-${BUILD_ARCH} NOT SUPPORTED!!!"
        fi
    else
        error "${BUILD_OS} NOT SUPPORTED!!!"
        exit 1
    fi
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
    echo "Found kubectl!"
fi
