terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Use latest version of provider in non-basic examples to verify latest version works with module
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.56.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.4"
    }
  }
}
