# Complete example with byok encryption, CBR rules and storing credentials in secrets manager

An end-to-end example that uses the module's default variable values. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance and store credentials in secrets manager.
- Create Key Protect instance with root key.
- Backend encryption using generated Key Protect key.
- Create a Sample VPC.
- Create Context Based Restriction(CBR) to only allow Postgresql to be accessible from the VPC.
