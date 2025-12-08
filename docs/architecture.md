# **Architecture Overview**
```
rdservicepros-site/
├── .github
│   └── workflows
│       └── deploy.yml            # GitHub Actions: sync site to S3 + invalidate CDN
│
├── .gitignore                    # Ignore Terraform state, DS_Store, IDE folders
├── .tfsec.yml                    # tfsec config with safe suppressions
├── LICENSE                       # MIT License + branding rights
├── README.md                     # Full project documentation with diagrams
│
├── docs
│   ├── architecture.md           # High-level system architecture (S3 → CloudFront → Route53 → GitHub OIDC)
│   └── screenshots               # Screenshots embedded into README
│       ├── 1-frontend-home.png   
│       ├── 2-cloudfront-general.png
│       ├── 3-s3-permissions.png
│       ├── 4-s3-objects.png
│       ├── 5-github-actions-deploy.png
│       └── 6-dns-dig-google.png
│
├── infra
│   └── terraform
│       ├── .checkov.yaml         # Checkov security policy for IaC
│       ├── backend.tf            # Remote state backend (S3 + DynamoDB)
│       ├── main.tf               # Core infrastructure configuration
│       ├── outputs.tf            # Useful outputs for CI/CD
│       ├── providers.tf          # AWS providers (default + us-east-1)
│       └── variables.tf          # Project variables (region, domain, repo)
│
└── site
    ├── 404.html                  # Custom CloudFront error page
    ├── index.html                # Main landing page for RD Service Pros
    └── assets                    # All static website resources
```

## 1. System Flow
- User requests the website via browser.
- Route53 resolves the domain to the CloudFront distribution.
- CloudFront checks the edge cache.
- If the object is not cached, CloudFront fetches it from S3 using OAC.
- S3 returns the object only to CloudFront (direct access is blocked).
- CloudFront serves the response to the user.

## 2. S3 Origin (Private)
- Bucket is private; public ACLs and public access are disabled.
- BucketOwnerEnforced mode is enabled.
- Only CloudFront (via Origin Access Control) can read objects.
- Direct S3 access returns AccessDenied by design.

## 3. CloudFront Distribution
- Origin Access Control (OAC) provides secure access to the S3 origin.
- ACM certificate issued in us-east-1 for HTTPS.
- Caching strategy:
  - HTML: 60 seconds TTL
  - Static assets: 1 year TTL
- Automatic cache invalidation after deployment.
- Custom 404 page supported.
- HTTPS-only access enforced.

## 4. Route53 DNS
- Hosted zone contains apex and www A-alias records pointing to CloudFront.
- DNS validation records created for ACM.
- Registrar nameservers must match hosted zone.
- Previous incident was caused by outdated registrar NS values.

## 5. CI/CD Pipeline (GitHub Actions with OIDC)
- GitHub Actions authenticates using OIDC (no long-lived AWS keys).
- Pipeline steps:
  1. Assume IAM deployment role.
  2. Sync static assets to S3.
  3. Upload HTML separately with short TTL.
  4. Trigger CloudFront invalidation.
- Produces repeatable and secure deployments.

## 6. Terraform Infrastructure
- Remote state stored in S3 with DynamoDB state locking.
- Two AWS providers:
  - Default regional provider.
  - us-east-1 provider for ACM certificates.
- Terraform provisions:
  - S3 bucket (private origin)
  - CloudFront distribution
  - Route53 hosted zone and records
  - IAM role for GitHub Actions
- Terraform outputs are used by CI/CD.

## 7. Security Model
- Full HTTPS enforcement.
- S3 origin locked to CloudFront only.
- IAM permissions follow least-privilege.
- No static secrets stored in the repository.
- Deployment uses OIDC for temporary credentials.

## 8. Design Decisions
- OAC preferred over OAI due to simplicity and modern security model.
- S3 versioning, logging, and WAF omitted for cost-efficiency.
- Architecture optimized for static brochure-type websites.
- TTL split ensures fast HTML updates without sacrificing asset caching.

## 9. Threat Model (Summary)
- No dynamic backend, no user input.
- No sensitive data stored or transmitted.
- Attack surface limited to CloudFront HTTPS endpoint.
- S3 origin not reachable from the internet.
- IAM exposure prevented by OIDC (no persistent credentials).

## 10. Known Limitations
- No WAF (intentionally excluded to avoid unnecessary cost).
- No object versioning; rollbacks must be manual via new deploy.
- CloudFront invalidations incur small costs for large deployments.
- Single-region architecture (us-east-1 certificate dependency).

## 11. Potential Future Improvements
- Add CloudFront Function for security headers.
- Add CI pipeline with automated TFLint / tfsec / Checkov.
- Add Lighthouse performance report for the frontend.
- Optional: enable S3 access logs for audit use cases.
