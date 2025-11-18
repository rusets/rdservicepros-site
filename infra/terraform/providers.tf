############################################
# Terraform Core Settings
# Purpose: lock TF version and AWS provider
############################################
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

############################################
# AWS Provider (Default Region)
# Purpose: main provider for regional resources
############################################
provider "aws" {
  region = var.aws_region
}

############################################
# AWS Provider (us-east-1)
# Purpose: required for ACM certificates for CloudFront
############################################
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
