
# Disable block public access for bucket policy
# resource "aws_s3_bucket_public_access_block" "public_access_block" {
#   bucket = data.aws_s3_bucket.static_website.id
#
#   block_public_acls       = true
#   block_public_policy     = false # This allows the bucket policy to make the bucket publicly accessible
#   ignore_public_acls      = true
#   restrict_public_buckets = false
# }
#
# # S3 Bucket Website Configuration
# resource "aws_s3_bucket_website_configuration" "website_config" {
#   bucket = data.aws_s3_bucket.static_website.bucket
#
#   index_document {
#     suffix = "index.html"
#   }
#
#   error_document {
#     key = "error.html"
#   }
# }
#
# # S3 Bucket Policy to allow CloudFront access to objects
# resource "aws_s3_bucket_policy" "static_website_policy" {
#   bucket = data.aws_s3_bucket.static_website.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = {
#           AWS = aws_cloudfront_origin_access_identity.origin_identity.iam_arn        }
#         Action    = "s3:GetObject"
#         Resource  = "${data.aws_s3_bucket.static_website.id}/*"
#       }
#     ]
#   })
#
#   depends_on = [
#     aws_cloudfront_origin_access_identity.origin_identity,
#     aws_s3_bucket_public_access_block.public_access_block
#   ]
# }