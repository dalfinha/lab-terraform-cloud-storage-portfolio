variable "bucket_name" {
  description   = "Nome do Bucket onde será hospedado o site"
  default       = "portifolio-dalfinha-net"
  type          = string
}

variable "project_id" {
  description = "ID do projeto criado no GCP"
  type        = number
}

variable "project_folder" {
  description = "Pasta que contém os arquivos do site"
  default     = "portfolio"
  type        = string
}