provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# used by the restapi provider to authenticate the API call based on API key
data "ibm_iam_auth_token" "token_data" {
}

provider "restapi" {
  uri                   = "https:"
  alias                 = "kp"
  write_returns_object  = false
  create_returns_object = false
  debug                 = false # set to true to show detailed logs, but use carefully as it might print sensitive values.
  headers = {
    Authorization    = data.ibm_iam_auth_token.token_data.iam_access_token
    Bluemix-Instance = module.key_protect_all_inclusive.key_protect_guid
    Content-Type     = "application/vnd.ibm.kms.policy+json"
  }
}

provider "restapi" {
  alias                = "sm"
  uri                  = "https:"
  write_returns_object = true
  debug                = false
  headers = {
    Authorization = data.ibm_iam_auth_token.token_data.iam_access_token
    Content-Type  = "application/json"
  }
}

# RestAPI provider using alternate configuration to be used by SM module
provider "restapi" {
  alias                 = "nocontent"
  uri                   = "https:"
  write_returns_object  = false
  create_returns_object = false
  debug                 = false # set to true to show detailed logs, but use carefully as it might print sensitive values.
  headers = {
    Accept        = "application/json"
    Authorization = data.ibm_iam_auth_token.token_data.iam_access_token
    Content-Type  = "application/json"
  }
}
