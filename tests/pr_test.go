// Tests in this file are run in the PR pipeline
package test

import (
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"log"
	"os"
	"testing"
)

const fsCloudTerraformDir = "examples/fscloud"
const completeExampleTerraformDir = "examples/complete"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

// Allow the tests to create a unique resource group for every test to ensure tests do not clash. This is due to the fact that the auth policy created by this module has to be scoped to the resource group and hence would clash if tests used same resource group.
//const resourceGroup = "geretain-test-postgres"

// For FSCloud test restricting region as Hyper Protect Crypto Service permanent instance deployed in 'us-south'
const region = "us-south"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func TestRunFSCloudExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fsCloudTerraformDir,
		Prefix:       "pg-compliant",
		TerraformVars: map[string]interface{}{
			"region":                     region,
			"existing_kms_instance_guid": permanentResources["hpcs_south"],
			"kms_key_crn":                permanentResources["hpcs_south_root_key_crn"],
			"pg_version":                 "14", // Always lock to the latest supported Postgres version
		},
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeCompleteExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       completeExampleTerraformDir,
		Prefix:             "postgres-upg",
		BestRegionYAMLPath: regionSelectionPath,
		TerraformVars: map[string]interface{}{
			"pg_version": "11", // Always lock to the lowest supported Postgres version
		},
	})

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
