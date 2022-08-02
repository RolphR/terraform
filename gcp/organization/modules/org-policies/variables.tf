variable "parent_type" {
  type    = string
  default = "project"
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

variable "allowed_geos_and_regions" {
  type        = list(string)
  default     = null
  description = "Limit resources to these geos and regions"
}

variable "allowed_iam_domains" {
  type = object({
    organization_domain = bool
    all_users           = bool
    additional_domains  = list(string)
  })
  default = null
}

variable "allowed_vms_with_external_ip_addresses" {
  type    = list(string)
  default = null
}

variable "enforce_public_access_prevention" {
  type    = bool
  default = null
}

variable "enforce_uniform_bucket_level_access" {
  type    = bool
  default = null
}

variable "restrict_cloudsql_public_ip" {
  type    = bool
  default = null
}
