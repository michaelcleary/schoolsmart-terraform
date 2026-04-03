variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
}

variable "repository_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_token_secret_name" {
  description = "Secrets Manager secret name containing the GitHub App installation token"
  type        = string
}

variable "branch_name" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "stage" {
  description = "Amplify branch stage (PRODUCTION, BETA, DEVELOPMENT)"
  type        = string
  default     = "PRODUCTION"
}

variable "domain_name" {
  description = "Root domain name (e.g. schoolsmart.co.uk)"
  type        = string
}

variable "domain_prefix" {
  description = "Subdomain prefix (e.g. 'app', 'dev-app'). Empty string for apex."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID in the shared account"
  type        = string
}

variable "environment_variables" {
  description = "App-level environment variables"
  type        = map(string)
  default     = {}
}

variable "branch_environment_variables" {
  description = "Branch-level environment variables"
  type        = map(string)
  default     = {}
}
