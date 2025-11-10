# Lessons Table
resource "aws_dynamodb_table" "engagements_table" {
  name           = "${var.env}-schoolsmart-admin-engagements"
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
    name = "studentId"
    type = "S"
  }

  attribute {
    name = "startDate"
    type = "S"
  }

  global_secondary_index {
    name            = "tutorId-startDate-index"
    hash_key        = "tutorId"
    range_key       = "startDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "studentId-startDate-index"
    hash_key        = "studentId"
    range_key       = "startDate"
    projection_type = "ALL"
  }

}
