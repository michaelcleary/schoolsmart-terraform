locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
  github_repo     = "michaelcleary/schoolsmart-terraform"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count    = var.create_github_oidc_provider ? 1 : 0
  provider = aws.management

  url             = local.github_oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_terraform" {
  count    = var.create_github_oidc_provider ? 1 : 0
  provider = aws.management
  name     = "github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.management_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# AdministratorAccess on the management account lets the role assume
# OrganizationAccountAccessRole into any member account, which is exactly
# what the Terraform providers do today.
resource "aws_iam_role_policy_attachment" "github_actions_terraform_admin" {
  count      = var.create_github_oidc_provider ? 1 : 0
  provider   = aws.management
  role       = aws_iam_role.github_actions_terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
