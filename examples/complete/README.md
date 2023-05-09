# Complete example with BYOK encryption, autoscaling, CBR rules, VPE creation and read-only replica provisioning

An end-to-end example that uses the module's default variable values. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance with auto-scaling (automatically increase resources) enabled.
- Create Key Protect instance with root key.
- Backend encryption using generated Key Protect key.
- Create a Sample VPC.
- Create Context Based Restriction(CBR) to only allow Postgresql to be accessible from the VPC.
- Create a VPE.
- Create a read-only replica of the leader Postgresql database instance.
