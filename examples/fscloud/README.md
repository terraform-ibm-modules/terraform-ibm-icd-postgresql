# Financial Services Cloud profile example

An end-to-end example that uses the [Profile for IBM Cloud Framework for Financial Services](../../profiles/fscloud/) to deploy an instance of IBM Cloud Databases for PostgreSQL.

The example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in.
- An IAM authorization between the PostgreSQL database resource group and the Hyper Protect Crypto Services permanent instance.
- An IBM Cloud Databases PostgreSQL database instance and credentials that are encrypted with the Hyper Protect Crypto Services resources that are passed in.
- A sample virtual private cloud (VPC).
- A context-based restriction (CBR) rule to prevent access from the VPC except to the PostgreSQL database.

:exclamation: **Important:** In this example, only the IBM Cloud Databases for PostgreSQL instance complies with the IBM Cloud Framework for Financial Services. Other parts of the infrastructure do not necessarily comply.

## Before you begin

- You need Hyper Protect Crypto Service instances available in the two regions that you want to deploy your PostgreSQL database instance.
- You must deploy into an account that complies with the framework.
