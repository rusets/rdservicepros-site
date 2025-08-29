terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ACM для CloudFront должен быть строго в us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

