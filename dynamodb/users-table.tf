# Lessons Table
resource "aws_dynamodb_table" "users_table" {
  name           = "${var.env}-schoolsmart-admin-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "username"

  attribute {
    name = "username"
    type = "S"
  }

  attribute {
    name = "contactId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "contactId-createdAt-index"
    hash_key        = "contactId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

}
