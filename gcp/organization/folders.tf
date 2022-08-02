locals {
  folders = {
    SECURED_FOLDER_ID = {
      display_name = "Security"
      overlay_permissions = {
      }
      allow_public_cloudsql_instances = false
      allowed_iam_domains = {
        organization_domain = true
        additional_domains  = []
        all_users           = false
      }
      allowed_geos_and_regions = [
        "eu"
      ]
      allowed_vms_with_external_ip_addresses = []
      deny_important_folder_changes          = true
      deny_important_project_changes         = true
      enforce_private_buckets                = true
      enforce_public_access_prevention       = true
      enforce_uniform_bucket_level_access    = true
      restrict_cloudsql_public_ip            = true
    }
    SYSTEM_GSUITE_FOLDER_ID = {
      display_name = "system-gsuite"
      overlay_permissions = {
      }
    }
  }
}

data "google_folder" "folder" {
  for_each = local.folders

  folder = each.key
  lifecycle {
    postcondition {
      condition     = self.display_name == each.value["display_name"]
      error_message = "Folder display name doesn't match given name: please verify that the correct folder_id is supplied and that the display names match"
    }
  }
}

resource "google_folder_iam_policy" "folder" {
  for_each = local.folders

  folder      = data.google_folder.folder[each.key].name
  policy_data = data.google_iam_policy.folder[each.key].policy_data
}

data "google_iam_policy" "folder" {
  for_each = local.folders

  dynamic "binding" {
    for_each = each.value.overlay_permissions

    content {
      role    = binding.key
      members = binding.value
    }
  }
}

module "folder-iam-deny" {
  for_each = local.folders

  source              = "./modules/iam-deny"
  parent_type         = "folder"
  organization_domain = local.organization.domain
  folder_id           = data.google_folder.folder[each.key].folder_id
  iam_deny_default_denied_principals = {
    "allUsers" = [],
  }
  iam_deny_default_excepted_principals = {
    "groups" = [local.config.super_admins_group],
  }
  deny_important_generic_changes      = lookup(each.value, "deny_important_generic_changes", false)
  deny_important_organization_changes = false
  deny_important_folder_changes       = lookup(each.value, "deny_important_folder_changes", false)
  deny_important_project_changes      = lookup(each.value, "deny_important_project_changes", false)
}

module "folder-org-policies" {
  for_each = local.folders

  source              = "./modules/org-policies"
  parent_type         = "folder"
  folder_id           = data.google_folder.folder[each.key].folder_id
  organization_domain = local.organization.domain

  allowed_geos_and_regions               = lookup(each.value, "allowed_geos_and_regions", null)
  allowed_vms_with_external_ip_addresses = lookup(each.value, "allowed_vms_with_external_ip_addresses", null)
  enforce_public_access_prevention       = lookup(each.value, "enforce_public_access_prevention", null)
  enforce_uniform_bucket_level_access    = lookup(each.value, "enforce_uniform_bucket_level_access", null)
  restrict_cloudsql_public_ip            = lookup(each.value, "restrict_cloudsql_public_ip", null)
}
