// Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package e2e_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/vmware-tanzu/community-edition/cli/cmd/plugin/unmanaged-cluster/test/e2e/utils"
	"log"
	"testing"
)

func TestE2e(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "E2e Suite")
}

var _ = BeforeSuite(func() {
	Describe("TCE installation...", func() {
		err := e2e.InstallTCE()
		if err != nil {
			log.Println("error while installing TCE")
		}
		Expect(err).NotTo(HaveOccurred())
	})
})

var _ = AfterSuite(func() {

})
