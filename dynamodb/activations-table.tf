# Lessons Table
resource "aws_dynamodb_table" "activations_table" {
  name           = "${var.env}-schoolsmart-admin-activations"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

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
    name            = "username-createdAt-index"
    hash_key        = "username"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "contactId-createdAt-index"
    hash_key        = "contactId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

}
