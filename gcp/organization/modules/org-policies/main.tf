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
}

resource "google_org_policy_policy" "gcp-resourceLocations" {
  count = var.allowed_geos_and_regions != null ? 1 : 0

  name   = "${local.parent_resource}/policies/gcp.resourceLocations"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = [
          for x in var.allowed_geos_and_regions :
          substr(x, -10, -1) == "-locations" ? "in:${x}" : "in:${x}-locations"
        ]
        denied_values = []
      }
    }
  }
}

resource "google_org_policy_policy" "iam-allowedPolicyMemberDomains" {
  count = var.allowed_iam_domains != null ? 1 : 0

  name   = "${local.parent_resource}/policies/iam.allowedPolicyMemberDomains"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = formatlist(
          "is:%s",
          lookup(var.allowed_iam_domains, "all_users", false) ? [] : flatten([
            var.allowed_iam_domains.organization_domain ? data.google_organization.organization[0].directory_customer_id : [],
            var.allowed_iam_domains.additional_domains
          ])
        )
        denied_values = []
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.organization_domain != null && var.allowed_iam_domains.organization_domain == true
      error_message = "The iam.allowedPolicyMemberDomains policy requires the organization_domain variable to be set"
    }
  }
}

resource "google_org_policy_policy" "compute-vmExternalIpAccess" {
  count = var.allowed_vms_with_external_ip_addresses != null ? 1 : 0

  name   = "${local.parent_resource}/policies/compute.vmExternalIpAccess"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false

    dynamic "rules" {
      for_each = length(var.allowed_vms_with_external_ip_addresses) == 0 ? ["deny_all"] : []

      content {
        deny_all = "TRUE"
      }
    }
    dynamic "rules" {
      for_each = length(var.allowed_vms_with_external_ip_addresses) == 0 ? [] : [var.allowed_vms_with_external_ip_addresses]

      content {
        values {
          allowed_values = rules.value
          denied_values  = []
        }
      }
    }
  }
}

resource "google_org_policy_policy" "storage-publicAccessPrevention" {
  count = var.enforce_public_access_prevention != null ? 1 : 0

  name   = "${local.parent_resource}/policies/storage.publicAccessPrevention"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false
    rules {
      enforce = var.enforce_public_access_prevention ? "TRUE" : "FALSE"
    }
  }
}

resource "google_org_policy_policy" "storage-uniformBucketLevelAccess" {
  count = var.enforce_uniform_bucket_level_access != null ? 1 : 0

  name   = "${local.parent_resource}/policies/storage.uniformBucketLevelAccess"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false
    rules {
      enforce = var.enforce_uniform_bucket_level_access ? "TRUE" : "FALSE"
    }
  }
}

resource "google_org_policy_policy" "sql-restrictPublicIp" {
  count = var.restrict_cloudsql_public_ip != null ? 1 : 0

  name   = "${local.parent_resource}/policies/sql.restrictPublicIp"
  parent = local.parent_resource

  spec {
    inherit_from_parent = false
    rules {
      enforce = var.restrict_cloudsql_public_ip ? "TRUE" : "FALSE"
    }
  }
}
