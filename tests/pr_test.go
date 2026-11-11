// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const fullyConfigurableSolutionTerraformDir = "solutions/fully-configurable"
const fullyConfigurableGen2SolutionTerraformDir = "solutions/fully-configurable-gen2"

const icdType = "postgresql"
const icdShortType = "pg"

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

func GetLatestAndOldestVersions(icdAvailableVersions []string) (string, string) {

	if len(icdAvailableVersions) == 0 {
		log.Fatal("No available ICD versions found")
	}

	sort.Slice(icdAvailableVersions, func(i, j int) bool {
		partsI := strings.Split(icdAvailableVersions[i], ".")
		partsJ := strings.Split(icdAvailableVersions[j], ".")

		majorI, _ := strconv.Atoi(partsI[0])
		majorJ, _ := strconv.Atoi(partsJ[0])

		if majorI != majorJ {
			return majorI < majorJ
		}

		minorI := 0
		minorJ := 0

		if len(partsI) >= 2 {
			minorI, _ = strconv.Atoi(partsI[1])
		}
		if len(partsJ) >= 2 {
			minorJ, _ = strconv.Atoi(partsJ[1])
		}
		return minorI < minorJ
	})

	fmt.Println("version list is ", icdAvailableVersions)
	latestVersion := icdAvailableVersions[len(icdAvailableVersions)-1]
	oldestVersion := icdAvailableVersions[0]

	return latestVersion, oldestVersion

}

func GetRegionVersions(region string) (string, string) {

	icdRegion := region
	if region == "ca-mon" {
		icdRegion = "ca-tor"
	}

	cloudInfoSvc, err := cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{
		IcdRegion: icdRegion,
	})

	if err != nil {
		log.Fatal(err)
	}

	icdAvailableVersions, err := cloudInfoSvc.GetAvailableIcdVersions(icdType)

	if err != nil {
		log.Fatal(err)
	}

	return GetLatestAndOldestVersions(icdAvailableVersions)
}

func GetVersionsGen2(region string, plan string) (string, string) {

	cloudInfoSvc, err := cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	if err != nil {
		log.Fatal(err)
	}

	icdAvailableVersions, err := cloudInfoSvc.GetAvailableIcdVersionsGen2("databases-for-postgresql", plan, region) // this function takes service, plan and region as arguments in this specific order

	if err != nil {
		log.Fatal(err)
	}

	return GetLatestAndOldestVersions(icdAvailableVersions)
}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	var err error
	sharedInfoSvc, err = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	if err != nil {
		log.Fatal(err)
	}

	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

// Test the fully-configurable DA with defaults (IBM owned encryption keys)
func TestRunFullyConfigurableSolutionSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableSolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigurableSolutionTerraformDir,
		BestRegionYAMLPath:         regionSelectionPath,
		Prefix:                     fmt.Sprintf("%s-fc-da", icdShortType),
		ResourceGroup:              resourceGroup,
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     60,
		CheckApplyResultForUpgrade: true,
	})

	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := []map[string]string{
		{
			"name":     "postgresql-admin",
			"role":     "Administrator",
			"endpoint": "private",
		},
	}

	region := "us-south"
	latestVersion, _ := GetRegionVersions(region)
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "existing_resource_group_name", Value: uniqueResourceGroup, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "service_credential_names", Value: serviceCredentialNames, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "admin_pass_secrets_manager_secret_group", Value: fmt.Sprintf("%s-%s-admin-secrets", icdShortType, options.Prefix), DataType: "string"},
		{Name: "admin_pass_secrets_manager_secret_name", Value: options.Prefix, DataType: "string"},
		{Name: "admin_pass", Value: common.GetRandomPasswordWithPrefix(), DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_eufr2_crn"], DataType: "string"},
		{Name: "existing_backup_kms_key_crn", Value: permanentResources["kp_multitenant_us_south_root_key_crn"], DataType: "string"},
		{Name: "kms_endpoint_type", Value: "private", DataType: "string"},
		{Name: "postgresql_version", Value: latestVersion, DataType: "string"}, // Always lock this test into the latest supported PostgreSQL version
	}

	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicTest()
	})
	assert.Nil(t, err, "This should not have errored")
}

func setupFullyConfigurableGen2Options(t *testing.T, prefix string) (*testschematic.TestSchematicOptions, string) {
	// ResourceGroup is intentionally not set so a unique group is created per run for this test.
	// Independent backup policies may not be destroyed on failure, causing conflicts on re-runs within the same group.
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableGen2SolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigurableGen2SolutionTerraformDir,
		Prefix:                     prefix,
		DeleteWorkspaceOnFail:      false,
		CheckApplyResultForUpgrade: true,
	})

	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := []map[string]string{
		{
			"name":     "postgresql-admin",
			"role":     "Manager",
			"endpoint": "private",
		},
	}

	// Temporary external issues. Hardcoding can be removed when external features are addressed
	// Hard code region ca-mon, the test function to lookup latest does not work in Montreal, no classic endpoint
	// Hard code version 18, because latest can not be looked (see also region)
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "existing_resource_group_name", Value: uniqueResourceGroup, DataType: "string"},
		{Name: "region", Value: "ca-mon", DataType: "string"},
		{Name: "service_credential_names", Value: serviceCredentialNames, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["kp_multitenant_us_south_crn"], DataType: "string"},
		{Name: "postgresql_version", Value: "18", DataType: "string"}, // Always lock this test into the latest supported PostgreSQL version
	}

	return options, uniqueResourceGroup
}

func TestRunFullyConfigurableGen2SolutionSchematics(t *testing.T) {
	t.Parallel()

	options, uniqueResourceGroup := setupFullyConfigurableGen2Options(t, fmt.Sprintf("%s-gen2da", icdShortType))
	options.WaitJobCompleteMinutes = 60

	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicTest()
	})
	assert.Nil(t, err, "This should not have errored")
}

// Upgrade test for Gen2 fully-configurable DA
func TestRunFullyConfigurableGen2UpgradeSolutionSchematics(t *testing.T) {
	t.Parallel()

	options, uniqueResourceGroup := setupFullyConfigurableGen2Options(t, fmt.Sprintf("%s-gen2-upg", icdShortType))
	options.WaitJobCompleteMinutes = 120

	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicUpgradeTest()
	})
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

// Upgrade test the fully-configurable DA with KMS encryption (KYOK)
func TestRunFullyConfigurableWithKMSUpgradeSolution(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableSolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigurableSolutionTerraformDir,
		Tags:                       []string{fmt.Sprintf("%s-fc-upg", icdShortType)},
		Prefix:                     fmt.Sprintf("%s-fc-upg", icdShortType),
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     120,
		CheckApplyResultForUpgrade: true,
	})

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := []map[string]string{
		{
			"name":     "admin",
			"role":     "Administrator",
			"endpoint": "private",
		},
		{
			"name":     "user1",
			"role":     "Viewer",
			"endpoint": "private",
		},
		{
			"name":     "user2",
			"role":     "Editor",
			"endpoint": "private",
		},
	}

	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	region := "us-south"
	latestVersion, _ := GetRegionVersions(region)
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: uniqueResourceGroup, DataType: "string"},
		{Name: "service_credential_names", Value: serviceCredentialNames, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "admin_pass_secrets_manager_secret_group", Value: fmt.Sprintf("%s-%s-admin-secrets", icdShortType, options.Prefix), DataType: "string"},
		{Name: "admin_pass_secrets_manager_secret_name", Value: options.Prefix, DataType: "string"},
		{Name: "admin_pass", Value: common.GetRandomPasswordWithPrefix(), DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["kp_multitenant_us_south_crn"], DataType: "string"},
		{Name: "postgresql_version", Value: latestVersion, DataType: "string"}, // Always lock this test into the latest supported PostgreSQL version
	}
	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicUpgradeTest()
	})
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func generateUniqueResourceGroupName(baseName string) string {
	id := uuid.New().String()[:8] // Shorten UUID for readability
	return fmt.Sprintf("%s-%s", baseName, id)
}

func TestRunRestoredDBGen2Example(t *testing.T) {
	t.Parallel()
	// ResourceGroup is intentionally not set so a unique group is created per run for this test.
	// Independent backup policies may not be destroyed on failure, causing conflicts on re-runs within the same group.
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: "examples/backup",
		Prefix:       "g2-restored",
		TerraformVars: map[string]interface{}{
			"plan":                  "standard-gen2",
			"disk_mb":               permanentResources["postgresqlGen2DiskMb"],
			"postgresql_version":    permanentResources["postgresqlGen2Version"],
			"region":                permanentResources["postgresqlGen2Region"],
			"existing_database_crn": permanentResources["postgresqlGen2Crn"],
		},
		CloudInfoService: sharedInfoSvc,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
