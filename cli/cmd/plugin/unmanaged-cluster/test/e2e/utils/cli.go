package e2e

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/onsi/ginkgo"
)

func InstallTCE() error {
	err := runDeployScript("utils/install-dependencies.sh")
	if err != nil {
		log.Fatal(err)
		return err
	}
	wd, err := os.Getwd()
	if err != nil {
		log.Println("error while getting current working directory", err)
	}
	err = os.Chdir(wd + "/../../../../../..")
		if err != nil {
			log.Println("error while changing directory :", err)
			return err
		}
	return runDeployScript("test/build-tce.sh")
}


func runDeployScript(filename string) error {
	mwriter := io.MultiWriter(os.Stdout)
	cmd := exec.Command("/bin/bash", filename)
	cmd.Stderr = mwriter
	cmd.Stdout = mwriter
	err := cmd.Run() // blocks until sub process is complete
	if err != nil {
		log.Fatal(err)
	}
	return err
}

func Kubectl(input io.Reader, args ...string) (string, error) {
	return cliRunner("kubectl", input, args...)
}

func Tanzu(input io.Reader, args ...string) (string, error) {
	return cliRunner("tanzu", input, args...)
}

func cliRunner(name string, input io.Reader, args ...string) (string, error) {
	fmt.Fprintf(ginkgo.GinkgoWriter, "+ %s %s\n", name, strings.Join(args, " "))

	var stdOut bytes.Buffer
	mwriter := io.MultiWriter(&stdOut, os.Stderr)
	cmd := exec.Command(name, args...)
	cmd.Stdin = input
	cmd.Stdout = mwriter
	cmd.Stderr = mwriter

	err := cmd.Run()
	if err != nil {
		rc := -1
		if ee, ok := err.(*exec.ExitError); ok {
			rc = ee.ExitCode()
		}

		return "", fmt.Errorf("%s\nexit status: %d", err.Error(), rc)
	}

	return stdOut.String(), err
}
