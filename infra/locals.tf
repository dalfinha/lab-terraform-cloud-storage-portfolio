locals {
  website_files = fileset("${path.module}/site-pages", "**")
}