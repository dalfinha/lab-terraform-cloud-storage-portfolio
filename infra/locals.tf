locals {
  website_files = fileset("${path.module}/${var.project_folder}", "**")
}