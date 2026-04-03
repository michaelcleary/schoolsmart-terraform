output "app_id" {
  value       = aws_amplify_app.this.id
  description = "Amplify app ID — used by CI/CD to trigger deployments"
}

output "branch_name" {
  value       = aws_amplify_branch.this.branch_name
  description = "Deployed branch name"
}

output "default_domain" {
  value       = aws_amplify_app.this.default_domain
  description = "Amplify-assigned default domain ({app_id}.amplifyapp.com)"
}

output "custom_domain" {
  value       = var.domain_prefix != "" ? "${var.domain_prefix}.${var.domain_name}" : var.domain_name
  description = "Custom domain for this environment"
}
