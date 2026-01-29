// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

func TestRunRestoredDBExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       "examples/backup",
		Prefix:             "pg-backup",
		BestRegionYAMLPath: regionSelectionPath,
		ResourceGroup:      resourceGroup,
		CloudInfoService:   sharedInfoSvc,
	})

	region := options.Region
	latestVersion, _ := GetRegionVersions(region)
	options.TerraformVars["postgresql_version"] = latestVersion

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunPointInTimeRecoveryDBExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/pitr",
		Prefix:        "pg-pitr",
		ResourceGroup: resourceGroup,
		Region:        fmt.Sprint(permanentResources["postgresqlPITRRegion"]),
		TerraformVars: map[string]interface{}{
			"pitr_id":            permanentResources["postgresqlPITRCrn"],
			"pitr_time":          "", // if blank string is passed, earliest_point_in_time_recovery_time will be used to restore
			"postgresql_version": permanentResources["postgresqlPITRVersion"],
			"members":            "3", // Lock members to 3 as the permanent postgres instances has 3 members
		},
		CloudInfoService: sharedInfoSvc,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       "examples/complete",
		Prefix:             "pg-complete",
		BestRegionYAMLPath: regionSelectionPath,
		ResourceGroup:      resourceGroup,
		CloudInfoService:   sharedInfoSvc,
	})

	region := options.Region
	latestVersion, _ := GetRegionVersions(region)
	options.TerraformVars["postgresql_version"] = latestVersion

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunBasicExampleWithFlavorMultitenant(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       "examples/basic",
		Prefix:             "pg-flvr-multitenant",
		BestRegionYAMLPath: regionSelectionPath,
		ResourceGroup:      resourceGroup,
		TerraformVars: map[string]interface{}{
			"member_host_flavor": "multitenant",
		},
		CloudInfoService: sharedInfoSvc,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
