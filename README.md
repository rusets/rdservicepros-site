# 🧰 RD Service Pros --- Production Static Website (S3 + CloudFront + Terraform)

![Terraform](https://img.shields.io/badge/Terraform-IaC-5C4EE5?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20CloudFront%20%7C%20Route53-FF9900?logo=amazonaws)
![CI/CD](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions)
![Security](https://img.shields.io/badge/Security-OIDC%20%7C%20IAM-2E7D32?logo=security)
![Region](https://img.shields.io/badge/Region-us--east--1-blue)

A fully automated, production-grade static website for **RD Service
Pros**, a home repair & appliance service company in **Navarre,
Florida**.\
The project demonstrates **end-to-end DevOps engineering**, including
infrastructure-as-code, CDN-level optimization, secure deployments, and
real incident resolution.

## 🌐 Live Demo

👉 **https://rdservicepros.com**

Built using **AWS S3 + CloudFront**, with DNS routed through
**Route53**, and deployed via **GitHub Actions OIDC** (no access keys).

## 🏗️ Tech Stack Overview

  -----------------------------------------------------------------------
  Layer            Technology                     Purpose
  ---------------- ------------------------------ -----------------------
  **Frontend**     HTML5, Bootstrap 5, Vanilla JS Responsive,
                                                  production-ready static
                                                  site

  **Hosting**      S3 (private)                   Secure static content
                                                  origin

  **CDN**          CloudFront (OAC)               HTTPS, edge caching,
                                                  compression

  **DNS**          Route53                        Apex + www A-aliases,
                                                  ACM DNS validation

  **Security**     OIDC, IAM Roles                Zero access keys, least
                                                  privilege

  **IaC**          Terraform                      Full provisioning and
                                                  configuration

  **CI/CD**        GitHub Actions                 Automated deploy +
                                                  invalidation
  -----------------------------------------------------------------------

## 🏆 Production-Grade Features

-   Multi-account domain setup (registrar in A → hosted zone +
    CloudFront in B)\
-   Private S3 bucket --- **no public ACLs**, access only via CloudFront
    OAC\
-   ACM certificate in `us-east-1` for CloudFront, DNS-validated\
-   Smart caching strategy:
    -   **HTML = 60 seconds**\
    -   **Assets = 1 year**\
-   Zero access keys --- GitHub Actions assumes IAM role via OIDC\
-   Automatic CloudFront invalidations on deploy\
-   Fully reproducible infrastructure using Terraform\
-   Custom 404 page + forced HTTPS\
-   Clean resource naming & consistent tagging

## ⚡ Performance Optimizations

This static hosting setup is tuned for **fast global delivery** and
**low-cost performance**:

### **1. Smart Cache Strategy**

-   **HTML → 60s TTL**
-   **Static assets → 1 year TTL**
-   Automatic CloudFront invalidations per deploy

### **2. Compression & HTTP Optimization**

-   Brotli/Gzip compression\
-   HTTP/2 & HTTP/3 support\
-   Optimized assets

### **3. Edge-Cached Routing**

-   Apex + www served entirely from CloudFront\
-   \~400 global edge locations

### **4. Zero Redirect Chain**

-   HTTPS-only\
-   Proper domain aliasing

### **5. Cost Optimization**

-   PriceClass_100\
-   Zero compute\
-   High cache-hit ratio

## 📊 Architecture Diagram (Mermaid)

``` mermaid
graph TD
    A[User Browser 🌐] -->|HTTPS| B[CloudFront CDN]
    B -->|Origin Request| C[S3 Bucket (Private)]
    B -->|DNS Lookup| D[Route53 Hosted Zone]

    subgraph CI/CD
        E[GitHub Actions] -->|OIDC AssumeRole| F[IAM Role]
        E -->|Sync static files| C
        E -->|Invalidate cache| B
    end

    subgraph AWS Cloud
        C --> B
        D --> B
    end
```

## 📁 Project Structure
```
    rdservicepros-site/
    ├── docs
    │   └── screenshots/
    ├── infra/
    │   └── terraform/
    │       ├── providers.tf
    │       ├── variables.tf
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── ...
    ├── site/
    │   ├── assets/
    │   ├── index.html
    │   └── ...
    └── README.md
```

## ⚙️ How to Deploy (CI/CD or Manual)

### Terraform

``` bash
cd infra/terraform
terraform init
terraform apply
```

### Manual Deployment

``` bash
aws s3 sync site s3://$(terraform output -raw bucket_name) --delete

aws cloudfront create-invalidation     --distribution-id $(terraform output -raw cloudfront_distribution_id)     --paths "/*"
```

## 🚨 Real Incident Case Study (DNS Failure Fix)

### Symptoms

-   `www.rdservicepros.com` worked\
-   `rdservicepros.com` failed globally

### Root Cause

Registrar NS did not match newly created Route53 hosted zone.

### Fix

-   Updated NS at registrar\
-   Recreated A-alias records\
-   Validated global propagation

### Lessons

-   Always verify hosted zone → registrar sync\
-   CloudFront TLS depends on correct DNS\
-   Use `dig` and Cloudflare DNS for validation

## 🔍 Highlights & Engineering Decisions

-   OAC instead of OAI (modern secure origin auth)\
-   BucketOwnerEnforced mode\
-   Dual A-alias routing\
-   Split TTL caching\
-   Strict IAM OIDC roles\
-   Terraform with create_before_destroy for ACM\
-   Multi-line, comment-structured Terraform (Ruslan AWS style)

## 🧠 What This Project Demonstrates

-   Real production static hosting\
-   Strong AWS infrastructure knowledge\
-   Secure CI/CD\
-   Real-world DNS debugging\
-   Clean Terraform architecture

## 🧾 License & Branding

MIT License.\
"Ruslan AWS 🚀" branding is protected.
