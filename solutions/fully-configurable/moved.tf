moved {
  from = module.postgresql_db
  to   = module.postgresql_db[0]
}
