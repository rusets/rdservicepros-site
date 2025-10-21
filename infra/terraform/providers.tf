terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

# Terraform core & providers
# - Terraform >= 1.6
# - AWS provider ~> 5.56
# Ensures reproducible builds across environments.

provider "aws" {
  region = var.aws_region
}

# Default AWS provider
# - Region comes from var.aws_region
# - Used by all regional resources

# ACM для CloudFront должен быть строго в us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Aliased AWS provider (us_east_1)
# - Region fixed to us-east-1
# - Needed for ACM certificates used by CloudFront
