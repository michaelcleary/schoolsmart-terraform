# Dedicated S3 bucket for OpenNext (Next.js) static assets (apps/next/.open-next/assets),
# separate from the schoolsmart-lambda bucket that holds Lambda deployment zips —
# those zips have SESSION_SECRET, COGNITO_CLIENT_ID, and COGNITO_REGION baked in and
# must never be public, while static assets must be publicly readable via CloudFront.
# See schoolsmart-terraform-4ur / schoolsmart-admin-xm5.
#
# Like schoolsmart-lambda and schoolsmart-admin-website, this bucket lives once in the
# shared services account and is reused by all three env workspaces (dev/test/prod),
# each eventually selecting its own release via origin_path = "/${release_tag}" when
# it's wired up as a CloudFront origin (schoolsmart-terraform-dl3, item 3 — not done
# yet, so no bucket policy statement can be scoped to a real distribution ARN today).
#
# dev/test/prod are separate AWS accounts applying from separate workspace state, so a
# plain `resource "aws_s3_bucket"` applied from all three would collide (2nd/3rd apply
# fails to create a bucket name that already exists). Only the workspace with
# create_shared_buckets = true (dev) actually creates it; the others look it up via a
# data source, exactly like the existing shared buckets.

locals {
  nextjs_assets_bucket_name = "schoolsmart-nextjs-assets"
}

resource "aws_s3_bucket" "nextjs_assets" {
  count    = var.create_shared_buckets ? 1 : 0
  provider = aws.shared
  bucket   = local.nextjs_assets_bucket_name

  tags = {
    Name = "NextjsAssetsBucket"
  }
}

data "aws_s3_bucket" "nextjs_assets" {
  count    = var.create_shared_buckets ? 0 : 1
  provider = aws.shared
  bucket   = local.nextjs_assets_bucket_name
}

locals {
  nextjs_assets_bucket_id  = var.create_shared_buckets ? aws_s3_bucket.nextjs_assets[0].id : data.aws_s3_bucket.nextjs_assets[0].id
  nextjs_assets_bucket_arn = var.create_shared_buckets ? aws_s3_bucket.nextjs_assets[0].arn : data.aws_s3_bucket.nextjs_assets[0].arn
}

# Public ACLs stay blocked; the bucket policy below is the only path to public read,
# and that path is scoped to CloudFront (OAC) only.
resource "aws_s3_bucket_public_access_block" "nextjs_assets" {
  count    = var.create_shared_buckets ? 1 : 0
  provider = aws.shared
  bucket   = local.nextjs_assets_bucket_id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Grants CloudFront OAC read access, one statement per env AWS account. Each env's
# future CloudFront distribution (schoolsmart-terraform-dl3) lives in that env's own
# account, so this can't yet be scoped to a specific distribution ARN — no distribution
# exists in any env until dl3 item 3 is built. Scoping to aws:SourceAccount instead of
# aws:SourceArn is the AWS-documented fallback for that case; tighten each statement to
# aws:SourceArn once the corresponding env's distribution exists.
resource "aws_s3_bucket_policy" "nextjs_assets" {
  count    = var.create_shared_buckets && length(var.env_account_ids) > 0 ? 1 : 0
  provider = aws.shared
  bucket   = local.nextjs_assets_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for env, account_id in var.env_account_ids : {
        Sid       = "AllowCloudFrontRead${title(env)}"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${local.nextjs_assets_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.nextjs_assets]
}
