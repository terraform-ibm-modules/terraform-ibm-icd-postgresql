# FS Cloud profile example

An example using the fscloud profile to deploy a compliant PostgreSQL instance: This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance and credentials.
- Create Key Protect instance with root key.
- Backend encryption using generated Key Protect key.
- Create a Sample VPC.
- Create Context Based Restriction(CBR) to only allow Postgresql to be accessible from the VPC.
