// Tests in this file are run in the PR pipeline
package test

import (
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const defaultExampleTerraformDir = "examples/default"
const autoscaleExampleTerraformDir = "examples/autoscale"
const fsCloudTerraformDir = "examples/fscloud"
const completeExampleTerraformDir = "examples/complete"

// Use existing resource group
const resourceGroup = "geretain-test-postgres"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

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

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        region,
	})
	return options
}

func TestRunDefaultExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "postgres", defaultExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAutoscaleExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "pg-autoscale", autoscaleExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunFSCloudExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "pg-fscloud", fsCloudTerraformDir)
	options.TerraformVars["existing_hpcs_instance_guid"] = permanentResources["hpcs_east"]

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func testRunCompleteExample(t *testing.T, version string) {
	t.Parallel()

	options := setupOptions(t, "pg-complete", completeExampleTerraformDir)
	options.TerraformVars["pg_version"] = version

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()
	versions := []string{"11", "12", "13", "14"}
	for _, version := range versions {
		t.Run(version, func(t *testing.T) { testRunCompleteExample(t, version) })
	}
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "postgres-upg", defaultExampleTerraformDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
