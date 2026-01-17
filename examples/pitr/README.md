# Point in time recovery example (PITR)

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-postgresql-pitr-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/examples/pitr"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example provides an end-to-end solution that:

- Creates a new resource group if one is not passed in.
- Creates a new ICD Postgresql database instance.
- Creates a new PostgreSQL instance pointing to a PITR time.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
