# Point in time recovery example (PITR)

This example provides an end-to-end creation of a new PostgreSQL instance, then creating a new PostgreSQL instance pointing to a PITR time. This example uses the IBM Cloud terraform provider to:

- Create a new resource group if one is not passed in.
- Create a new ICD Postgresql database instance.
- Create a new PostgreSQL instance pointing to a PITR time.
