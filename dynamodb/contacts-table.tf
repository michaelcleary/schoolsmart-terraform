# Lessons Table
resource "aws_dynamodb_table" "contacts_table" {
  name           = "${var.env}-schoolsmart-admin-contacts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "clientId"
    type = "S"
  }

  attribute {
    name = "client"
    type = "S"
  }

  attribute {
    name = "child"
    type = "S"
  }

  attribute {
    name = "tutor"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "clientId-createdAt-index"
    hash_key        = "clientId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "client-name-index"
    hash_key        = "client"
    range_key       = "name"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "child-name-index"
    hash_key        = "child"
    range_key       = "name"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "tutor-name-index"
    hash_key        = "tutor"
    range_key       = "name"
    projection_type = "ALL"
  }

}
