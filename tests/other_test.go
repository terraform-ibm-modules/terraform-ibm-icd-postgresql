// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"testing"
)

const restoredTerraformDir = "examples/backup"
const replicaExampleTerraformDir = "examples/replica"
const autoscaleExampleTerraformDir = "examples/autoscale"

func TestRunRestoredDBExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: restoredTerraformDir,
		Prefix:       "pg-backup",
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAutoscaleExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       autoscaleExampleTerraformDir,
		Prefix:             "pg-autoscale",
		BestRegionYAMLPath: regionSelectionPath,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func testRunReplicaExample(t *testing.T, version string) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       replicaExampleTerraformDir,
		Prefix:             "pg-replica",
		BestRegionYAMLPath: regionSelectionPath,
		TerraformVars: map[string]interface{}{
			"pg_version": version,
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunReplicaExample(t *testing.T) {
	t.Parallel()
	versions := []string{"11", "12", "13", "14"}
	for _, version := range versions {
		t.Run(version, func(t *testing.T) { testRunReplicaExample(t, version) })
	}
}
