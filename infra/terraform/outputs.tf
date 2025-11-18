############################################
# Outputs — static website infrastructure
# Purpose: expose bucket, CDN, DNS, and CI/CD role
############################################

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "route53_nameservers" {
  value = aws_route53_zone.primary.name_servers
}

output "gha_deploy_role_arn" {
  value = aws_iam_role.gha_deploy.arn
}
