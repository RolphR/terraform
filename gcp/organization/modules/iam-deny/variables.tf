variable "parent_type" {
  type    = string
  default = null
  validation {
    condition     = contains(["organization", "folder", "project"], var.parent_type)
    error_message = "Expected one of [organization, folder, project]"
  }
}

variable "organization_domain" {
  type        = string
  default     = null
  description = "Organization ID (domain.tld)"
}

variable "folder_id" {
  type        = number
  default     = null
  description = "Folder ID (number)"
}

variable "project_id" {
  type        = string
  default     = null
  description = "Project ID (string)"
}


variable "iam_deny_default_denied_principals" {
  type = map(list(string))
  default = {
    "allUsers" = [],
  }
  description = "Valid keys: [allUsers, groups, users, serviceAccounts, domains]"
}

variable "iam_deny_default_excepted_principals" {
  type = map(list(string))
  default = {
    "groups" = ["gcp-super-users@domain"],
  }
  description = "Valid keys: [allUsers, groups, users, serviceAccounts, domains]"
}

variable "deny_important_generic_changes" {
  type        = bool
  default     = false
  description = "Deny modifications to important generic settings"
}

variable "deny_important_organization_changes" {
  type        = bool
  default     = false
  description = "Deny modifications to important organization settings"
}

variable "deny_important_folder_changes" {
  type        = bool
  default     = false
  description = "Deny modifications to important folder settings"
}

variable "deny_important_project_changes" {
  type        = bool
  default     = false
  description = "Deny modifications to important project settings"
}

variable "iam_deny_additional_rules" {
  type = list(object({
    description         = string
    denied_principals   = map(list(string))
    excepted_principals = map(list(string))
    permissions         = list(string)
    denial_condition = list(object({
      title      = string
      expression = string
    }))
  }))
  default     = []
  description = "Additional IAM Deny Policies"
}
