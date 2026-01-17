# Complete example with BYOK encryption, CBR rules and VPE creation

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-postgresql-complete-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/examples/complete"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An end-to-end example that does the following:

- Create a new resource group if one is not passed in.
- Create Key Protect instance with root key.
- Create a new ICD PostgreSQL database instance with BYOK encryption.
- Set 250 max connection for ICD PostgreSQL database instance.
- Create service credentials for the database instance.
- Create a Virtual Private Cloud (VPC).
- Create Context Based Restriction (CBR) to only allow Postgresql to be accessible from the VPC.
- Create a security group and a VPE for the PostgreSQL instance.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
