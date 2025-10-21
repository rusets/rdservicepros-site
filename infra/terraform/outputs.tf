# -----------------------------
# Outputs for static website stack
# Used by CI/CD and deployment scripts
# -----------------------------

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

# S3 bucket hosting the static website
# Use this value to sync files:
# aws s3 sync ./site s3://<bucket_name> --delete


output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

# CloudFront distribution ID
# Use this value to invalidate cache:
# aws cloudfront create-invalidation --distribution-id <id> --paths "/*"


output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

# CloudFront domain (CNAME target)
# Example:
# dxxxx.cloudfront.net → add Route53 A/AAAA alias pointing to this domain


output "route53_nameservers" {
  value = aws_route53_zone.primary.name_servers
}

# Route53 hosted zone nameservers
# Add these at your domain registrar to delegate DNS to Route53


output "gha_deploy_role_arn" {
  value = aws_iam_role.gha_deploy.arn
}

# GitHub Actions IAM Role (OIDC)
# Add this ARN in your repo settings to allow CI/CD deployments
