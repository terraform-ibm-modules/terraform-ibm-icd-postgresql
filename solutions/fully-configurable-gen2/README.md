# IBM Cloud Databases Gen 2 (VPC) for PostgreSQL

This deployable architecture provides a fully configurable solution for IBM Cloud Databases Gen 2 (VPC) for PostgreSQL. For more information about Gen 2, see [Databases for PostgreSQL Gen 2](https://cloud.ibm.com/docs/databases-for-postgresql-gen2?topic=databases-for-postgresql-gen2-provisioning&interface=ui).

:exclamation: **Important:** This solution is not intended to be called by other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
