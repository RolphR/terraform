locals {
  projects = {
    DUMMY_PROJECT_ID = {
      name = "DUMMY_PROJECT_ID"
    }
    DUMMY_PROJECT2_ID = {
      name                            = "DUMMY_PROJECT2_ID"
      allow_public_cloudsql_instances = false
      allowed_iam_domains = {
        organization_domain = true
        all_users           = false
        additional_domains  = []
      }
      deletion_protection_enabled    = true
      deletion_protection_reason     = "This project contains all important data and should not be deleted"
      deny_important_generic_changes = false
      deny_important_project_changes = true
      enforce_private_buckets        = true
    }
    BILLING_PROJECT_ID = {
      name                        = "BILLING_PROJECT_ID"
      deletion_protection_enabled = true
      deletion_protection_reason  = "This project contains important tooling and should not be deleted"
    }
    AUDIT_LOGGING_PROJECT_ID = {
      name                        = "AUDIT_LOGGING_PROJECT_ID"
      deletion_protection_enabled = true
      deletion_protection_reason  = "This project routes all audit logs and should not be deleted"
    }
  }
}

data "google_project" "project" {
  for_each = local.projects

  project_id = each.key
  lifecycle {
    postcondition {
      condition     = self.name == each.value["name"]
      error_message = "Project name doesn't match given name: please verify that the correct project_id is supplied and that the names match"
    }
  }
}

module "project-iam-deny" {
  for_each = local.projects

  source              = "./modules/iam-deny"
  parent_type         = "project"
  organization_domain = local.organization.domain
  project_id          = each.key
  iam_deny_default_denied_principals = {
    "allUsers" = [],
  }
  iam_deny_default_excepted_principals = {
    "groups" = [local.config.super_admins_group],
  }
  deny_important_generic_changes      = lookup(each.value, "deny_important_generic_changes", false)
  deny_important_organization_changes = false
  deny_important_folder_changes       = false
  deny_important_project_changes      = lookup(each.value, "deny_important_project_changes", false)
}

module "project-lien" {
  for_each = local.projects

  source     = "./modules/project-lien"
  project_id = each.key
  reason     = lookup(each.value, "deletion_protection_reason", "This project has deletion protection set by Terraform")
  enabled    = lookup(each.value, "deletion_protection_enabled", false)
}

module "project-org-policies" {
  for_each = local.projects

  source              = "./modules/org-policies"
  parent_type         = "project"
  project_id          = each.key
  organization_domain = local.organization.domain

  allowed_geos_and_regions               = lookup(each.value, "allowed_geos_and_regions", null)
  allowed_vms_with_external_ip_addresses = lookup(each.value, "allowed_vms_with_external_ip_addresses", null)
  enforce_public_access_prevention       = lookup(each.value, "enforce_public_access_prevention", null)
  enforce_uniform_bucket_level_access    = lookup(each.value, "enforce_uniform_bucket_level_access", null)
  restrict_cloudsql_public_ip            = lookup(each.value, "restrict_cloudsql_public_ip", null)
}
