output "bucket_name" {
  description = "Nome do bucket criado"
  value       = google_storage_bucket.static_site.name
}

output "website_url" {
  description = "URL de acesso ao site"
  value       = "https://storage.googleapis.com/${google_storage_bucket.static_site.name}/site-pages/index.html"
}