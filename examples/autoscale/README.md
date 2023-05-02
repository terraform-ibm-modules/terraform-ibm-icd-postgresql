# Autoscale example

An end-to-end example that uses the module's default variable values. This example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group if one is not passed in.
- An ICD Postgresql database instance with autoscaling (automatically increase resources) enabled.

:exclamation: **Important:** Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs.
