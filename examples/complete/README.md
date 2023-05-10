# Complete example with BYOK encryption, autoscaling, CBR rules, VPE creation and read-only replica provisioning

An end-to-end example that uses the module's default variable values.

This example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in.
- An instance of the IBM Cloud Databases for PostgreSQL with autoscaling (automatically increases resources) enabled.
- A Key Protect instance with a root key.
- Backend encryption that uses the generated Key Protect key.
- A sample virtual private cloud (VPC).
- A context-based restriction (CBR) rule to prevent access from the VPC except to the PostgreSQL database.
- A security group and a virtual private endpoint (VPE) for the PostgreSQL instance
- A read-only replica of the leader PostgreSQL database instance.

:exclamation: **Important:** Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs.
