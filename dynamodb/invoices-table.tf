# Lessons Table
resource "aws_dynamodb_table" "invoices_table" {
  name           = "${var.env}-schoolsmart-admin-invoices"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "tutorId"
    type = "S"
  }

  attribute {
    name = "period"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "reference"
    type = "S"
  }

  global_secondary_index {
    name            = "tutorId-period-index"
    hash_key        = "tutorId"
    range_key       = "period"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "period-date-index"
    hash_key        = "period"
    range_key       = "date"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "reference-index"
    hash_key        = "reference"
    range_key       = "date"
    projection_type = "ALL"
  }

}
