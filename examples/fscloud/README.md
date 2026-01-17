# Financial Services Cloud profile example with autoscaling enabled

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=icd-postgresql-fscloud-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/examples/fscloud"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An end-to-end example that uses the [Profile for IBM Cloud Framework for Financial Services](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/modules/fscloud) to deploy an instance of IBM Cloud Databases for PostgreSQL.

The example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in.
- An IAM authorization between all PostgreSQL database instances in the given resource group, and the Hyper Protect Crypto Services instance that is passed in.
- An IBM Cloud Databases PostgreSQL database instance that is encrypted with the Hyper Protect Crypto Services root key that is passed in.
- Autoscaling rules for the IBM Cloud Databases PostgreSQL database instance.
- Service Credentials for the PostgreSQL database instance.
- A sample virtual private cloud (VPC).
- A context-based restriction (CBR) rule to only allow PostgreSQL to be accessible from within the VPC.

:exclamation: **Important:** In this example, the IBM Cloud Databases for PostgreSQL module is compliant with the IBM Cloud Framework for Financial Services.

## Before you begin

- You need a Hyper Protect Crypto Services instance and root key available in the region that you want to deploy your PostgreSQL database instance to.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
