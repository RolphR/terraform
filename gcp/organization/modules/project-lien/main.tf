data "google_project" "project" {
  project_id = var.project_id
}

resource "google_resource_manager_lien" "lien" {
  count = var.enabled ? 1 : 0

  parent       = data.google_project.project.id
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-managed-lien"
  reason       = var.reason
}
