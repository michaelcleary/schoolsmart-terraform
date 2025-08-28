resource "aws_s3_bucket" "static_website" {
  bucket = var.website_bucket_name

  tags = {
    Name        = "StaticWebsiteBucket-${var.domain_name}"
    Environment = var.env
  }
}

# Disable block public access for bucket policy
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = false # This allows the bucket policy to make the bucket publicly accessible
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy to allow CloudFront access to objects
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_identity.id}"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_cloudfront_origin_access_identity.origin_identity,
    aws_s3_bucket_public_access_block.public_access_block
  ]
}