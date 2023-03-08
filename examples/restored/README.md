# Default example

An example that uses the module's default variable values. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance.
- Create a restored ICD Postgresql database instance pointing to the backup of the first instance.
