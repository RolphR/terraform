locals {
  ###
  # Configuration
  ###
  organization = {
    domain = "domain.tld"
    break_glass_permissions = [
      "roles/iam.denyAdmin",                     # Needed to update iam deny policies
      "roles/orgpolicy.policyAdmin",             # Needed to update Organization Policies
      "roles/resourcemanager.folderAdmin",       # Needed to manage folders
      "roles/resourcemanager.lienModifier",      # Needed to manage Project Liens
      "roles/resourcemanager.organizationAdmin", # Needed to grant additional access
    ]
    # These permissions are imported via the following command:
    # gcloud organizations get-iam-policy ORGANIZATION_ID --billing-project=BILLING_PROJECT_ID --format=json | jq -crM '.bindings|.[]|"\""+.role+"\":[\n"+(.members|map("\""+.+"\",")|join("\n"))+"]"'
    overlay_permissions = {
      "roles/billing.admin" : [
        "group:sre@domain.tld",
      ]
      "roles/billing.user" : [
        "serviceAccount:terraform@BILLING_PROJECT_ID.iam.gserviceaccount.com",
      ]
    }
  }

  ###
  # Calculated
  ###
  organization_iam_policy = transpose(merge(
    transpose(local.organization.overlay_permissions),
    {
      ("group:${local.config.super_admins_group}") : local.organization.break_glass_permissions
    }
  ))
}

data "google_organization" "organization" {
  domain = local.organization.domain
}

resource "google_organization_iam_policy" "organization" {
  org_id      = data.google_organization.organization.org_id
  policy_data = data.google_iam_policy.organization.policy_data
}

data "google_iam_policy" "organization" {
  dynamic "binding" {
    for_each = local.organization_iam_policy

    content {
      role    = binding.key
      members = binding.value
    }
  }
}

module "organization-iam-deny" {
  source              = "./modules/iam-deny"
  parent_type         = "organization"
  organization_domain = local.organization.domain
  iam_deny_default_denied_principals = {
    "allUsers" = [],
  }
  iam_deny_default_excepted_principals = {
    "groups" = [local.config.super_admins_group],
  }
  deny_important_generic_changes      = false
  deny_important_organization_changes = false
  deny_important_folder_changes       = false
  deny_important_project_changes      = false
}

resource "google_logging_organization_sink" "audit-logs" {
  name             = "audit_logs_sink"
  description      = ""
  org_id           = data.google_organization.organization.org_id
  destination      = "pubsub.googleapis.com/projects/AUDIT_LOGGING_PROJECT_ID/topics/audit-logs-sink"
  filter           = "logName:\"/logs/cloudaudit.googleapis.com\" AND -logName:\"/logs/cloudaudit.googleapis.com%2Fdata_access\""
  include_children = true
}
