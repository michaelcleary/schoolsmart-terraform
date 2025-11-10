# App Runner Implementation Documentation

## Overview

This document describes the implementation of an AWS App Runner service for hosting an application server deployed from a Docker image in ECR. The service is configured to handle API requests with a specific prefix.

## Implementation Details

### 1. App Runner Service

The App Runner service is configured to:
- Deploy from a Docker image stored in ECR
- Use IAM roles for ECR access
- Support configurable CPU and memory allocations
- Allow environment variables to be passed to the container

### 2. API Routing

API requests are routed to the App Runner service through:
- A dedicated CloudFront distribution
- Path-based routing using the configured API prefix (default: `/api`)
- A custom domain (api.{main_domain_name})

### 3. DNS Configuration

DNS is configured with:
- An A record for the api.{main_domain_name} subdomain pointing to the CloudFront distribution
- Certificate validation records for HTTPS support

## Usage

### Required Variables

To deploy the App Runner service, you must provide:

```hcl
app_runner_ecr_repo_url = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/my-repository"
```

### Optional Variables

The following variables have defaults but can be customized:

```hcl
app_runner_image_tag = "latest"
app_runner_port = 8080
app_runner_cpu = "1 vCPU"
app_runner_memory = "2 GB"
app_runner_environment_variables = {
  ENV = "production"
  LOG_LEVEL = "info"
}
app_runner_api_prefix = "/api"
```

### Outputs

The following outputs are available:

- `app_runner_service_url`: The direct App Runner service URL
- `app_runner_service_arn`: The ARN of the App Runner service
- `app_runner_api_endpoint`: The full API endpoint URL (https://api.{domain}{prefix})
- `app_runner_cloudfront_domain`: The CloudFront domain for the App Runner service

## Architecture

```
                                  ┌─────────────────┐
                                  │                 │
                                  │  Route53 (DNS)  │
                                  │                 │
                                  └────────┬────────┘
                                           │
                                           ▼
┌─────────────────┐            ┌─────────────────┐
│                 │            │                 │
│  Main Website   │◄───────────┤   CloudFront    │
│  (S3 Bucket)    │            │  Distribution   │
│                 │            │                 │
└─────────────────┘            └────────┬────────┘
                                        │
                                        │ /api/* requests
                                        ▼
                               ┌─────────────────┐
                               │                 │
                               │   App Runner    │
                               │    Service      │
                               │                 │
                               └────────┬────────┘
                                        │
                                        ▼
                               ┌─────────────────┐
                               │                 │
                               │  Docker Image   │
                               │  (from ECR)     │
                               │                 │
                               └─────────────────┘
```

## Security Considerations

- The App Runner service uses an IAM role with minimal permissions (ECR access only)
- HTTPS is enforced for all traffic
- CloudFront provides an additional layer of security and caching