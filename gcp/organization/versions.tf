terraform {
  required_version = "~> 1.2.0"

  backend "gcs" {
    bucket = "dbk-infra"
    prefix = "terraform/google-cloud/organization"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  user_project_override = true
  project               = local.config.billing_project
  billing_project       = local.config.billing_project
}
