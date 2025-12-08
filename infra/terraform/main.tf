############################################
# Locals — derived names
# Purpose: unify naming across resources
############################################
locals {
  bucket_name = "${var.project}-site"
}

############################################
# S3 Bucket — private storage for static site
# Purpose: origin for CloudFront via OAC
############################################
#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
}

############################################
# S3 Bucket Encryption — default SSE-S3
# Purpose: at-rest encryption without extra KMS cost
############################################
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# S3 Ownership Controls
# Purpose: enforce bucket-owner-only writes/read
############################################
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

############################################
# S3 Public Access Block
# Purpose: block all direct public access
############################################
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# Route53 Hosted Zone
# Purpose: DNS management for apex + www
############################################
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

############################################
# ACM Certificate (us-east-1)
# Purpose: TLS for CloudFront (must be in us-east-1)
############################################
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


############################################
# CloudFront OAC (Origin Access Control)
# Purpose: secure connection between CloudFront and S3
############################################
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  description                       = "OAC for ${aws_s3_bucket.site.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################################
# CloudFront Distribution
# Purpose: CDN for static content + TLS + domain aliases
############################################
#tfsec:ignore:aws-cloudfront-use-secure-tls-policy
#tfsec:ignore:aws-cloudfront-enable-waf
#tfsec:ignore:aws-cloudfront-enable-logging
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} static site"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  aliases = [
    var.domain_name,
    "www.${var.domain_name}"
  ]

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

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
  lifecycle {
    ignore_changes = [
      viewer_certificate[0].minimum_protocol_version
    ]
  }
  depends_on = [
    aws_acm_certificate.cert
  ]
}
