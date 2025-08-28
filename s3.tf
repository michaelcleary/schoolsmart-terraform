resource "aws_s3_bucket" "static_website" {
  bucket = var.website_bucket_name

  tags = {
    Name        = "StaticWebsiteBucket"
    Environment = "Production"
  }
}

# Disable block public access for bucket policy
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls   = true
  block_public_policy = false # This allows the bucket policy to make the bucket publicly accessible
  ignore_public_acls  = true
  restrict_public_buckets = false
}

# S3 Bucket Website Configuration (replaces 'website' block in the bucket)
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy to allow public access to objects
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = var.lambda_bucket_name

  tags = {
    Name        = "LambdaCodeBucket"
    Environment = "Production"
  }
}

