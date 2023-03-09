# Financial Services Cloud Profile Example

:exclamation: **Important:** This example deploys PostgreSQL in a compliant manner. Other infrastructure is not necessarily compliant.

For more information, see the documentation for the [Financial Services ICD PostgreSQL module](../../profiles/fscloud/).

An end-to-end example using the [Financial Services Cloud profile](../../profiles/fscloud/) to deploy a compliant PostgreSQL instance. This example uses the IBM Cloud Terraform provider and other modules to automate the following infrastructure:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance and credentials.
- Create Key Protect instance with root key.
- Instance encryption using the key protect key.
- Backups encryption using the key protect.
- Create a sample VPC (for illustration purpose)
- Create a Context Based Restriction(CBR) rule that makes the Postgresql instance data plane only accessible from compute resources located in the VPC.
