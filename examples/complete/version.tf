terraform {
  required_version = ">= 1.3.0, <1.7.0"
  required_providers {
    # Use latest version of provider in non-basic examples to verify latest version works with module
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">=1.62.0, <2.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.8.0"
    }
  }
}
