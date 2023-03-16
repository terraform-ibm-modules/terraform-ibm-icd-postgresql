# Restore from backup example

This example provides an end-to-end executable flow of how a PostgreSQL DB can be created from a backup instance. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance with auto-scaling enabled if no existing backup crn is provided.
- Create a restored ICD Postgresql database instance pointing to the backup of the first instance.
