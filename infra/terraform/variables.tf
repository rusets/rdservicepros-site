variable "project" {
  type    = string
  default = "rdservicepros"
}

variable "domain_name" {
  type    = string
  default = "rdservicepros.services"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_org" {
  type    = string
  default = "rusets"
}

variable "github_repo" {
  type        = string
  description = "Имя репозитория в GitHub (без org), например 'static-site'"
  default     = "static-site"
}

