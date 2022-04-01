// Copyright 2021-2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package e2e_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"log"
	"strconv"
	"math/rand"
	"github.com/vmware-tanzu/community-edition/cli/cmd/plugin/unmanaged-cluster/test/e2e/utils"
)

var _ = Describe("UnmanagedCluster", func() {
	Describe("Unmanaged Cluster testing ....", func() {
		
		// Random Unmanged Cluster Name
		clusterName := "uc" + strconv.Itoa( rand.Intn(10000) ) +"test"
		It("Unmanaged Cluster creation", func() {     
			_, err := e2e.Tanzu( nil, "unmanaged-cluster", "create", clusterName)
			if err != nil {
				log.Println("error while unmanaged cluster Creation")
			}
			Expect(err).NotTo(HaveOccurred())	
    	})

		It("Check for package repository", func() {     
			output, err := e2e.Tanzu( nil, "package", "repository", "list", "-A")
			if err != nil || output == "" {
				log.Println("error while checking for package repositories")
			}
			Expect(err).NotTo(HaveOccurred())	
    	})

		It("Check for pods", func() {     
			_, err := e2e.Kubectl( nil, "get", "pods", "-A")
			if err != nil {
				log.Println("error while checking for pods")
			}
			Expect(err).NotTo(HaveOccurred())	
    	})
		
		It("Unmanaged Cluster deletion", func() {
			_ , err := e2e.Tanzu( nil, "unmanaged-cluster", "delete", clusterName)
			if err != nil {
				log.Println("error while unmanaged cluster deletion")
			}
			Expect(err).NotTo(HaveOccurred())
			// Check for containers
			
		})

	})
})
