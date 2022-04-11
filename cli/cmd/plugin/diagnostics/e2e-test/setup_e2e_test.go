// Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
 
package e2e_test

import (
	"fmt"
	"testing"
	"os"
	"runtime"
	"io"
	"os/exec"
	"log"
)


const (
	colorReset = "\033[0m" // Reset
	colorBlue  = "\033[34m"
	colorRed   = "\033[31m" // Fail
	colorGreen = "\033[32m" // Pass
	TCE_VERSION = "v0.11.0"
	
 )

 func TestInitialisingVariable(t *testing.T) {
	//MY_DIR, _ = os.Getwd()
	MY_DIR,_ := os.Getwd()
	BUILD_OS := runtime.GOOS
	TCE_REPO_PATH := "/Users/amansha/go/src/github.com/vmware-tanzu/community-edition"
	TCE_RELEASE_TAR_BALL := "tce-" + BUILD_OS + "-amd64-" + TCE_VERSION + ".tar.gz"
	TCE_RELEASE_DIR := "tce-" + BUILD_OS + "-amd64-" + TCE_VERSION
	INSTALLATION_DIR := MY_DIR + "/tce-installation"
	
	fmt.Println(BUILD_OS)
	fmt.Println(MY_DIR)
	fmt.Println(TCE_RELEASE_TAR_BALL)
	fmt.Println(TCE_RELEASE_DIR)
	fmt.Println(INSTALLATION_DIR)
	fmt.Println(TCE_REPO_PATH)
	
	//runDeployScript(TCE_REPO_PATH + "/hack/get-tce-release.sh", TCE_VERSION, BUILD_OS + "-amd64")
	if err := os.Mkdir(INSTALLATION_DIR, os.ModePerm); err != nil {
        log.Fatal(err)
    }

	// tar
	runDeployScript(INSTALLATION_DIR + "/" + TCE_RELEASE_DIR + "/install.sh")
 }


 func runDeployScript(filename string, args ...string) error {
	mwriter := io.MultiWriter(os.Stdout)
	cmd := exec.Command(filename, args...)
	cmd.Stderr = mwriter
	cmd.Stdout = mwriter
	err := cmd.Run() // blocks until sub process is complete
	if err != nil {
		log.Fatal(err)
	}
	return err
 }
  
