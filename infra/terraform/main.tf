# -----------------------------
# Static Website Infrastructure: S3 + CloudFront + ACM + Route53 + GitHub OIDC
# This Terraform file sets up a secure static website hosted on AWS.
# -----------------------------
locals {
  bucket_name = "${var.project}-site"
}

# Derive the S3 bucket name from the project prefix
# (keeps naming consistent across resources)

# ---------- S3 bucket (private) ----------
# Create a private S3 bucket to store the website content
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true
}
# S3 bucket created (private, force_destroy enabled)

# Enforce ownership of S3 objects by the bucket owner (disables ACLs)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerEnforced" }
}
# Ownership controls applied (BucketOwnerEnforced)

# Block all public access; CloudFront will access the bucket via OAC
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Public access fully blocked

# ---------- Route 53 hosted zone ----------
# Create a Route53 hosted zone for domain DNS management
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}
# Hosted zone created for the domain

# ---------- ACM certificate (us-east-1) ----------
# Request a public certificate in us-east-1 for CloudFront (DNS validation)
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
}
# ACM certificate requested (DNS validation, us-east-1)

# Create DNS records in Route53 to validate the ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}
# DNS validation records created

# Finalize ACM validation using the DNS records created above
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
# ACM certificate validated

# ---------- CloudFront + OAC ----------
# Create CloudFront Origin Access Control (OAC) to securely access S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  description                       = "OAC for ${aws_s3_bucket.site.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
# OAC configured for S3 origin

# Configure CloudFront distribution for HTTPS-only delivery and caching
# - S3 origin via OAC, default_root=index.html, custom 404 page
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} static site"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  aliases = [var.domain_name, "www.${var.domain_name}"]

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3origin-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3origin-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    compress = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.cert]
}
# CloudFront distribution ready with aliases and TLS

# Allow the CloudFront distribution to read S3 objects securely via OAC
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = ["s3:GetObject"]
      Resource  = ["${aws_s3_bucket.site.arn}/*"]
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
        }
      }
    }]
  })
}
# Bucket policy restricts reads to this CloudFront distribution

# ---------- DNS: A/AAAA aliases to CloudFront ----------
# Apex A-alias pointing the root domain to CloudFront
resource "aws_route53_record" "apex_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
# Apex alias points to CloudFront

# www subdomain A-alias pointing to CloudFront
resource "aws_route53_record" "www_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
# www alias points to CloudFront

# ---------- GitHub OIDC + deploy role for CI/CD ----------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Current GitHub OIDC root certificate thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
# GitHub OIDC provider configured

# Trust policy allowing GitHub Actions to assume the deploy role via OIDC
data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Allow only pushes to main in the specific repository
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}
# Trust policy limits role assumption to main branch in repo

# IAM role assumed by GitHub Actions to deploy the static website
resource "aws_iam_role" "gha_deploy" {
  name               = "${var.project}-gha-deploy"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}
# Deploy role created for GitHub Actions

# Define permissions for S3 uploads and CloudFront invalidations
data "aws_iam_policy_document" "gha_deploy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetDistribution",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations"
    ]
    resources = [aws_cloudfront_distribution.cdn.arn]
  }
}
# Deploy permissions defined (S3 + CloudFront)

# Managed IAM policy attached to the deploy role
resource "aws_iam_policy" "gha_deploy" {
  name   = "${var.project}-gha-deploy"
  policy = data.aws_iam_policy_document.gha_deploy_doc.json
}
# Managed policy created

# Attach the managed policy to the GitHub Actions deploy role
resource "aws_iam_role_policy_attachment" "gha_deploy_attach" {
  role       = aws_iam_role.gha_deploy.name
  policy_arn = aws_iam_policy.gha_deploy.arn
}
# Policy attached to role
