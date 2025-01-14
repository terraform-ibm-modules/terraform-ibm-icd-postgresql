##############################################################################
# ICD read-only-replica extension for edb, mysql and postgresql
##############################################################################

# On destroy, after the replica has been returned as destroyed by terraform,
# the leader instance destroy can fail with: "You must delete all replicas
# before disabling the leader. Try again with valid values or contact support
# if the issue persists."
# The ICD team recommend to wait for a period of time after the replica
# destroy completes before attempting to destroy the leader instance, so
# hence adding a time sleep here.

resource "time_sleep" "wait_time" {
  depends_on = [module.database]

  destroy_duration = "5m"
}

##############################################################################
# ICD read-only-replica
##############################################################################

module "replica" {
  source             = "../.."
  resource_group_id  = module.resource_group.resource_group_id
  name               = "${var.prefix}-replica"
  pg_version         = var.db_version
  region             = var.region
  resource_tags      = var.resource_tags
  access_tags        = var.access_tags
  member_host_flavor = var.member_host_flavor
  remote_leader_crn  = module.database.crn
  depends_on         = [time_sleep.wait_time]
}
