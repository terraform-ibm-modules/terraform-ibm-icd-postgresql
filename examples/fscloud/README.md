# Financial Services Cloud Profile Example

:exclamation: **Important:** This example deploys PostgreSQL in a compliant manner. Other infrastructure is not necessarily compliant.

For more information, see the documentation for the [Financial Services ICD PostgreSQL module](../../profiles/fscloud/).

An end-to-end example using the [Financial Services Cloud profile](../../profiles/fscloud/) to deploy a compliant PostgreSQL instance. This example uses the IBM Cloud Terraform provider and other modules to automate the following infrastructure:

- Create a resource group if one is not passed in.
- Create an ICD PostgreSQL database instance and credentials.
- Create a Key Protect instance with a root key.
- Encrypt the instance by using the Key Protect key.
- Encrypt backups by using Key Protect.
- Create a sample VPC (for illustration purpose)
- Create a Context Based Restriction (CBR) rule that makes the PostgreSQL instance data plane accessible only from compute resources located in the VPC.
