output "invoices_table_stream_arn" {
  description = "The ARN of the DynamoDB stream for the invoices table"
  value       = aws_dynamodb_table.invoices_table.stream_arn
}
