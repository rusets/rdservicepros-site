############################################
# Remote state backend — S3 + DynamoDB
# Purpose: central Terraform state with locking
############################################
terraform {
  backend "s3" {
    bucket         = "rdservicepros-site-state"
    key            = "infra/terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rdservicepros-site-state"
    encrypt        = true
  }
}