data "google_organization" "organization" {
  count  = var.organization_domain != null ? 1 : 0
  domain = var.organization_domain
}

data "google_folder" "folder" {
  count  = var.folder_id != null ? 1 : 0
  folder = var.folder_id
}

data "google_project" "project" {
  count      = var.project_id != null ? 1 : 0
  project_id = var.project_id
}


locals {
  parent_resource = (
    var.parent_type == "organization" ? data.google_organization.organization[0].name : (
      var.parent_type == "folder" ? data.google_folder.folder[0].name : (
        var.parent_type == "project" ? data.google_project.project[0].id : null
      )
    )
  )

  iam_deny_formats = {
    "allUsers"        = "principalSet://goog/public:all"                               # any
    "users"           = "principal://goog/subject/%s"                                  # user email
    "groups"          = "principalSet://goog/group/%s"                                 # group email
    "serviceAccounts" = "principal://iam.googleapis.com/projects/-/serviceAccounts/%s" # service account email
    "domains"         = "principalSet://goog/cloudIdentityCustomerId/%s"               # domain customer id C0XXXXXX
  }

  iam_deny_default_denied_principal_list = flatten([
    for k, v in var.iam_deny_default_denied_principals : (
    k == "allUsers" ? [local.iam_deny_formats[k]] : [for p in v : format(local.iam_deny_formats[k], p)])
  ])
  iam_deny_default_excepted_principal_list = flatten([
    for k, v in var.iam_deny_default_excepted_principals : (
    k == "allUsers" ? [local.iam_deny_formats[k]] : [for p in v : format(local.iam_deny_formats[k], p)])
  ])

  deny_important_generic_changes_rule = {
    description         = "Deny modifications to important generic settings"
    denied_principals   = local.iam_deny_default_denied_principal_list
    excepted_principals = local.iam_deny_default_excepted_principal_list
    permissions = [
      "orgpolicy.googleapis.com/policy.set",
    ]
    denial_condition = [
      {
        expression = "true"
        title      = "dummy true"
      }
    ]
  }

  deny_important_organization_changes_rule = {
    description         = "Deny modifications to important organization settings"
    denied_principals   = local.iam_deny_default_denied_principal_list
    excepted_principals = local.iam_deny_default_excepted_principal_list
    permissions = [
      "cloudresourcemanager.googleapis.com/organizations.setIamPolicy",
    ]
    denial_condition = [
      {
        expression = "true"
        title      = "dummy true"
      }
    ]
  }

  deny_important_folder_changes_rule = {
    description         = "Deny modifications to important folder settings"
    denied_principals   = local.iam_deny_default_denied_principal_list
    excepted_principals = local.iam_deny_default_excepted_principal_list
    permissions = [
      "cloudresourcemanager.googleapis.com/folders.move",
      "cloudresourcemanager.googleapis.com/folders.setIamPolicy",
      "cloudresourcemanager.googleapis.com/folders.update",
    ]
    denial_condition = [
      {
        expression = "true"
        title      = "dummy true"
      }
    ]
  }

  deny_important_project_changes_rule = {
    description         = "Deny modifications to important project settings"
    denied_principals   = local.iam_deny_default_denied_principal_list
    excepted_principals = local.iam_deny_default_excepted_principal_list
    permissions = [
      "cloudresourcemanager.googleapis.com/projects.delete",
      "cloudresourcemanager.googleapis.com/projects.move",
      "cloudresourcemanager.googleapis.com/projects.updateLiens",
    ]
    denial_condition = [
      {
        expression = "true"
        title      = "dummy true"
      }
    ]
  }

  all_iam_deny_rules = flatten([
    var.deny_important_generic_changes ? [local.deny_important_generic_changes_rule] : [],
    var.deny_important_organization_changes ? [local.deny_important_organization_changes_rule] : [],
    var.deny_important_folder_changes ? [local.deny_important_folder_changes_rule] : [],
    var.deny_important_project_changes ? [local.deny_important_project_changes_rule] : [],
    var.iam_deny_additional_rules,
  ])
}

resource "google_iam_deny_policy" "iam-deny-policy" {
  count = length(local.all_iam_deny_rules) != 0 ? 1 : 0

  provider     = google-beta
  parent       = urlencode("cloudresourcemanager.googleapis.com/${local.parent_resource}")
  name         = "${var.parent_type}-deny-policy"
  display_name = "Terraform Managed deny rule on ${title(var.parent_type)}"

  dynamic "rules" {
    for_each = local.all_iam_deny_rules
    content {
      description = rules.value["description"]
      deny_rule {
        denied_principals    = rules.value["denied_principals"]
        exception_principals = rules.value["excepted_principals"]
        denied_permissions   = rules.value["permissions"]

        dynamic "denial_condition" {
          for_each = rules.value["denial_condition"]
          content {
            title      = denial_condition.value["title"]
            expression = denial_condition.value["expression"]
          }
        }
      }
    }
  }
}
