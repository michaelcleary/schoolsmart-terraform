# Lessons Table
resource "aws_dynamodb_table" "lessons_table" {
  name           = "${var.env}-schoolsmart-admin-lessons"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "tutorId"
    type = "S"
  }

  attribute {
    name = "engagementId"
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

  global_secondary_index {
    name            = "tutorId-date-index"
    hash_key        = "tutorId"
    range_key       = "date"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "engagementId-date-index"
    hash_key        = "engagementId"
    range_key       = "date"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "period-date-index"
    hash_key        = "period"
    range_key       = "date"
    projection_type = "ALL"
  }

}
