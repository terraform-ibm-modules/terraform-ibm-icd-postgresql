# Financial Services Cloud profile example

## *Note:* This example is only deploying Postgresql in a compliant manner the other infrastructure is not necessarily compliant.

An example using the fscloud profile to deploy a compliant Postgresql instance. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance and credentials.
- Create Key Protect instance with root key.
- Backend encryption using generated Key Protect key.
- Create a Sample VPC.
- Create Context Based Restriction(CBR) to only allow Postgresql to be accessible from the VPC.
