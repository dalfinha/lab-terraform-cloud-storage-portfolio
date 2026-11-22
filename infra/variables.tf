variable "bucket_name" {
  description   = "Nome do Bucket onde será hospedado o site"
  default       = "portifolio-dalfinha-net"
  type          = string
}

variable "project_id" {
  description = "ID do projeto criado no GCP"
  type        = number
}

