output "bucket_name" {
  description = "Nome do bucket criado"
  value       = google_storage_bucket.static_site.name
}

output "website_url" {
  description = "URL de acesso ao site"
  value       = "https://storage.googleapis.com/${google_storage_bucket.static_site.name}/${var.project_folder}/index.html"
}

output "not_found_url" {
  description = "URL com erros 404"
  value       = "https://storage.googleapis.com/${google_storage_bucket.static_site.name}/${var.project_folder}/404.html"
}