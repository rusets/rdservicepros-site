# -----------------------------
# Variables file for static website infrastructure
# Defines project-wide parameters such as domain, region, and GitHub settings
# -----------------------------

# Name of the overall project used for resource naming
variable "project" {
  type    = string
  default = "rdservicepros"
}

# Domain name for the static website hosted on CloudFront
variable "domain_name" {
  type    = string
  default = "rdservicepros.com"
}

# Default AWS region for resource deployment
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# GitHub organization name used in OIDC configuration
variable "github_org" {
  type    = string
  default = "rusets"
}

# Repository name within the GitHub organization for CI/CD
# (Example: 'static-site')
variable "github_repo" {
  type        = string
  description = "Repository name in GitHub (without org), for example 'static-site'"
  default     = "static-site"
}
