resource "aws_dynamodb_table" "admin_db" {
  name         = "${var.env}_SchoolSmartAdmin"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # GSI for retrieving engagements by client, tutor, or student
  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # GSI for retrieving lessons by tutor for a given month
  attribute {
    name = "GSI2PK"
    type = "S"
  }

  attribute {
    name = "GSI2SK"
    type = "S"
  }

  # Main table with composite primary key (PK, SK)
  global_secondary_index {
    name               = "${var.env}_GSI1"
    hash_key           = "GSI1PK"
    range_key          = "GSI1SK"
    projection_type    = "ALL"
  }

  global_secondary_index {
    name               = "${var.env}_GSI2"
    hash_key           = "GSI2PK"
    range_key          = "GSI2SK"
    projection_type    = "ALL"
  }

  tags = {
    Name        = "${var.env}_SchoolSmartAdminDB"
    Environment = "Production"
  }
}
