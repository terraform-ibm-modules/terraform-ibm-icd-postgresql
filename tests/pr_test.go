// Tests in this file are run in the PR pipeline
package test

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const fullyConfigurableSolutionTerraformDir = "solutions/fully-configurable"
const securityEnforcedSolutionTerraformDir = "solutions/security-enforced"
const fscloudExampleTerraformDir = "examples/fscloud"
const latestVersion = "17"

// Use existing resource group
const resourceGroup = "geretain-test-postgres"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

var sharedInfoSvc *cloudinfo.CloudInfoService
var validICDRegions = []string{
	"eu-de",
	"us-south",
}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func TestRunFullyConfigurableSolutionSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fmt.Sprintf("%s/*.tf", fullyConfigurableSolutionTerraformDir),
			fmt.Sprintf("%s/*.tf", fscloudExampleTerraformDir),
			fmt.Sprintf("%s/*.tf", "modules/fscloud"),
			fmt.Sprintf("%s/*.sh", "scripts"),
		},
		TemplateFolder:         fullyConfigurableSolutionTerraformDir,
		BestRegionYAMLPath:     regionSelectionPath,
		Prefix:                 "pg-fg-da",
		ResourceGroup:          resourceGroup,
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_backup_kms_key_crn", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		{Name: "kms_endpoint_type", Value: "private", DataType: "string"},
		{Name: "postgresql_version", Value: "16", DataType: "string"}, // Always lock this test into the latest supported PostgresSQL version
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "admin_pass", Value: GetRandomAdminPassword(t), DataType: "string"},
	}
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunSecurityEnforcedSolutionSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fmt.Sprintf("%s/*.tf", securityEnforcedSolutionTerraformDir),
			fmt.Sprintf("%s/*.tf", fullyConfigurableSolutionTerraformDir),
			fmt.Sprintf("%s/*.tf", fscloudExampleTerraformDir),
			fmt.Sprintf("%s/*.tf", "modules/fscloud"),
			fmt.Sprintf("%s/*.sh", "scripts"),
		},
		TemplateFolder:         securityEnforcedSolutionTerraformDir,
		BestRegionYAMLPath:     regionSelectionPath,
		Prefix:                 "pg-se-da",
		ResourceGroup:          resourceGroup,
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string", Secure: true},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_backup_kms_key_crn", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		{Name: "postgresql_version", Value: "16", DataType: "string"}, // Always lock this test into the latest supported PostgresSQL version
		{Name: "existing_resource_group_name", Value: "geretain-test-postgres-security-enforced", DataType: "string"},
		{Name: "admin_pass", Value: GetRandomAdminPassword(t), DataType: "string"},
	}
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunSecurityEnforcedUpgradeSolutionSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:       t,
		Region:        "us-south",
		Prefix:        "pg-se-upg",
		ResourceGroup: resourceGroup,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableSolutionTerraformDir + "/*.tf",
			securityEnforcedSolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             securityEnforcedSolutionTerraformDir,
		Tags:                       []string{"pg-se-upg"},
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     120,
		CheckApplyResultForUpgrade: true,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
	}

	err := options.RunSchematicUpgradeTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestPlanValidation(t *testing.T) {
	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  fullyConfigurableSolutionTerraformDir,
		Prefix:        "val-plan",
		ResourceGroup: resourceGroup,
		Region:        "us-south", // skip VPC region picker
	})
	options.TestSetup()
	options.TerraformOptions.NoColor = true
	options.TerraformOptions.Logger = logger.Discard
	options.TerraformOptions.Vars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"region":                       "us-south",
		"kms_endpoint_type":            "public",
		"postgresql_version":           "16",
		"provider_visibility":          "public",
		"existing_resource_group_name": resourceGroup,
	}

	// Test the DA when using IBM owned encryption keys
	var ibmOwnedEncryptionKeyTFVars = map[string]interface{}{
		"use_default_backup_encryption_key": false,
		"kms_encryption_enabled":            false,
	}

	// Test the DA when using Default Backup Encryption Key and not IBM owned encryption keys
	var notIbmOwnedEncryptionKeyTFVars = map[string]interface{}{
		"existing_kms_instance_crn":         permanentResources["hpcs_south_crn"],
		"use_default_backup_encryption_key": true,
		"kms_encryption_enabled":            true,
	}

	// Create a map of the variables
	tfVarsMap := map[string]map[string]interface{}{
		"ibmOwnedEncryptionKeyTFVars":    ibmOwnedEncryptionKeyTFVars,
		"notIbmOwnedEncryptionKeyTFVars": notIbmOwnedEncryptionKeyTFVars,
	}

	_, initErr := terraform.InitE(t, options.TerraformOptions)
	if assert.Nil(t, initErr, "This should not have errored") {
		// Iterate over the slice of maps
		for name, tfVars := range tfVarsMap {
			t.Run(name, func(t *testing.T) {
				// Iterate over the keys and values in each map
				for key, value := range tfVars {
					options.TerraformOptions.Vars[key] = value
				}
				output, err := terraform.PlanE(t, options.TerraformOptions)
				assert.Nil(t, err, "This should not have errored")
				assert.NotNil(t, output, "Expected some output")
				// Delete the keys from the map
				for key := range tfVars {
					delete(options.TerraformOptions.Vars, key)
				}
			})
		}
	}
}

func GetRandomAdminPassword(t *testing.T) string {
	// Generate a 15 char long random string for the admin_pass
	randomBytes := make([]byte, 13)
	_, randErr := rand.Read(randomBytes)
	require.Nil(t, randErr) // do not proceed if we can't gen a random password

	randomPass := "A1" + base64.URLEncoding.EncodeToString(randomBytes)[:13]

	return randomPass
}

func TestRunExistingInstance(t *testing.T) {
	t.Parallel()
	prefix := fmt.Sprintf("pg-t-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := ".."
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	rand, err := rand.Int(rand.Reader, big.NewInt(int64(len(validICDRegions))))
	if err != nil {
		fmt.Println("Error generating random number:", err)
		return
	}
	region := validICDRegions[rand.Int64()]

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir + "/examples/basic",
		Vars: map[string]interface{}{
			"prefix":             prefix,
			"region":             region,
			"postgresql_version": latestVersion,
			"service_endpoints":  "public-and-private",
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		logger.Log(t, " existing_postgresql_instance_crn: ", terraform.Output(t, existingTerraformOptions, "postgresql_crn"))
		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			TarIncludePatterns: []string{
				"*.tf",
				fmt.Sprintf("%s/*.tf", fullyConfigurableSolutionTerraformDir),
				fmt.Sprintf("%s/*.tf", fscloudExampleTerraformDir),
				fmt.Sprintf("%s/*.tf", "modules/fscloud"),
				fmt.Sprintf("%s/*.sh", "scripts"),
			},
			TemplateFolder:         fullyConfigurableSolutionTerraformDir,
			BestRegionYAMLPath:     regionSelectionPath,
			Prefix:                 "pg-da",
			ResourceGroup:          resourceGroup,
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "existing_postgresql_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "postgresql_crn"), DataType: "string"},
			{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "provider_visibility", Value: "public", DataType: "string"},
		}
		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")

	}
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}
