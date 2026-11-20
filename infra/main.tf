resource "google_storage_bucket" "static_site" {
  name          = "${var.bucket_name}-dev"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
  
  
  public_access_prevention = "inherited"

  website {
    main_page_suffix = "site-pages/index.html"
    not_found_page   = "site-pages/404.html"
  }
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.static_site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"

  depends_on = [google_storage_bucket_object.website_files]
}


resource "google_storage_bucket_object" "website_files" {
  for_each = local.website_files

  name   = "site-pages/${each.value}"
  bucket = google_storage_bucket.static_site.name
  source = "${path.module}/site-pages/${each.value}"
  cache_control = "no-cache, max-age=0"
}