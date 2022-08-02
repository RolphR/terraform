variable "project_id" {
  type        = string
  default     = null
  description = "Project ID (string)"
}

variable "reason" {
  type        = string
  default     = null
  description = "Human readable reason for setting a project lien"
}

variable "enabled" {
  type        = bool
  default     = false
  description = "Set the project lien"
}
