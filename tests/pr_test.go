// Tests in this file are run in the PR pipeline
package test

import (
	"crypto/rand"
	"encoding/base64"
	"log"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

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

func TestRunFSCloudExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: "examples/fscloud",
		Prefix:       "postgres-fscloud",
		Region:       "us-south", // For FSCloud locking into us-south since that is where the HPCS permanent instance is
		/*
		 Comment out the 'ResourceGroup' input to force this tests to create a unique resource group to ensure tests do
		 not clash. This is due to the fact that an auth policy may already exist in this resource group since we are
		 re-using a permanent HPCS instance. By using a new resource group, the auth policy will not already exist
		 since this module scopes auth policies by resource group.
		*/
		//ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"access_tags":                permanentResources["accessTags"],
			"existing_kms_instance_guid": permanentResources["hpcs_south"],
			"kms_key_crn":                permanentResources["hpcs_south_root_key_crn"],
			"pg_version":                 "15", // Always lock this test into the latest supported Postgres version
		},
	})
	options.SkipTestTearDown = true
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	// check if outputs exist
	outputs := terraform.OutputAll(options.Testing, options.TerraformOptions)
	expectedOutputs := []string{"port", "hostname"}
	_, outputErr := testhelper.ValidateTerraformOutputs(outputs, expectedOutputs...)
	assert.NoErrorf(t, outputErr, "Some outputs not found or nil")
	options.TestTearDown()
}

func TestRunDBConnectivity(t *testing.T) {
	t.Parallel()

	prefix := "postgres-db-connectivity"
	options_postgres := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/complete",
		Prefix:        prefix,
		Region:        "us-south",
		ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"vpc_network_acls": `[{
				name = "vpc-acl"
				add_ibm_cloud_internal_rules = true
				add_vpc_connectivity_rules   = true
				prepend_ibm_rules            = true
				rules = [
					{
						name        = "allow-all-inbound"
						action      = "allow"
						direction   = "inbound"
						destination = "10.10.10.64/32"
						source      = "0.0.0.0/0"
					  },
					  {
						name        = "allow-all-outbound"
						action      = "allow"
						direction   = "outbound"
						destination = "0.0.0.0/0"
						source      = "10.10.10.64/32"
					  }
				]
			}]`,
		},
	})
	options_postgres.SkipTestTearDown = true
	output_postgres, err_postgres := options_postgres.RunTest()
	assert.Nil(t, err_postgres, "This should not have errored")
	assert.NotNil(t, output_postgres, "Expected some output")

	outputs := terraform.OutputAll(options_postgres.Testing, options_postgres.TerraformOptions)

	var serviceCredential interface{}
	for _, data := range outputs["service_credentials_json"].(map[string]interface{}) {
		serviceCredential = data.(string)
		break
	}
	assert.NotNil(t, serviceCredential, "Unable to access service credentials")

	options_vsi := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: "tests/resources",
		Prefix:       prefix,
		Region:       "us-south",
		TerraformVars: map[string]interface{}{
			"resource_group_id":  outputs["resource_group_id"],
			"service_credential": serviceCredential,
			"vpc_id":             outputs["vpc_id"],
			"subnet_ids":         outputs["subnet_ids"],
			"vsi_reserved_ip":    "10.10.10.64",
		},
	})
	output_vsi, err_vsi := options_vsi.RunTestConsistency()
	options_postgres.TestTearDown()
	assert.Nil(t, err_vsi, "This should not have errored")
	assert.NotNil(t, output_vsi, "Expected some output")

}


func TestRunUpgradeCompleteExample(t *testing.T) {
	t.Parallel()

	// Generate a 10 char long random string for the admin_pass
	randomBytes := make([]byte, 10)
	_, err := rand.Read(randomBytes)
	randomPass := "A" + base64.URLEncoding.EncodeToString(randomBytes)[:10]

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       "examples/complete",
		Prefix:             "postgres-upg",
		BestRegionYAMLPath: regionSelectionPath,
		ResourceGroup:      resourceGroup,
		TerraformVars: map[string]interface{}{
			"pg_version": "11", // Always lock to the lowest supported Postgres version
			"users": []map[string]interface{}{
				{
					"name":     "testuser",
					"password": randomPass, // pragma: allowlist secret
					"type":     "database",
				},
			},
			"admin_pass": randomPass,
		},
	})

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
