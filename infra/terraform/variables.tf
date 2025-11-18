############################################
# Variables — static website infrastructure
# Purpose: project name, domain, region, GitHub OIDC settings
############################################

variable "project" {
  type    = string
  default = "rdservicepros"
}

variable "domain_name" {
  type    = string
  default = "rdservicepros.com"
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
  type    = string
  default = "static-site"
}
