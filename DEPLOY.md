# Deployment Guide

Infrastructure is deployed via the [Terraform Deploy](.github/workflows/deploy.yml) GitHub Actions workflow.

## Triggering a deploy

### From the GitHub UI

1. Go to **Actions → Terraform Deploy → Run workflow**
2. Select the target environment: `dev` or `prod`
3. Click **Run workflow**

### From another repository (cross-repo dispatch)

```bash
gh api repos/michaelcleary/schoolsmart-terraform/dispatches \
  --method POST \
  --field event_type=deploy \
  --field client_payload='{"environment":"dev"}'
```

## How it works

```
plan job  →  [manual approval for prod]  →  apply job
```

1. **Plan**: `terraform init` + `terraform plan -var-file=<env>.tfvars`. The plan output is posted to the workflow summary and saved as a 5-day artifact.
2. **Approval gate** (prod only): The `apply` job runs in the `production` GitHub Environment, which must be configured with required reviewers. A reviewer approves or rejects after inspecting the plan summary.
3. **Apply**: Downloads the saved plan file and runs `terraform apply` against it — no re-planning, so exactly what was reviewed is applied.

Dev deploys skip the approval gate and run automatically.

## AWS authentication (OIDC)

The workflow authenticates to AWS via **OIDC** — no long-lived credentials are stored as GitHub secrets. On each run, GitHub issues a short-lived JWT that the workflow exchanges for temporary AWS credentials by assuming the `github-actions-terraform` IAM role in the management account (`548144873869`). From there the existing `OrganizationAccountAccessRole` chain into dev/prod accounts works unchanged.

The IAM role and OIDC provider are defined in `github-actions.tf` and managed by Terraform itself (with `create_github_oidc_provider = true`, which is the default).

## First-time setup

### 1. Bootstrap the OIDC role (one-time)

The OIDC role must exist before the workflow can use it. Apply Terraform once from your local machine (using your existing AWS credentials) to create it:

```bash
terraform init
terraform apply -var-file=dev.tfvars -target=aws_iam_openid_connect_provider.github_actions -target=aws_iam_role.github_actions_terraform -target=aws_iam_role_policy_attachment.github_actions_terraform_admin
```

After this, all subsequent applies can run via GitHub Actions.

### 2. GitHub Actions variable

Add one **repository variable** (not a secret) in **Settings → Variables → Actions**:

| Variable | Value |
|---|---|
| `AWS_MANAGEMENT_ACCOUNT_ID` | `548144873869` |

### 3. GitHub Environments

Create two environments in **Settings → Environments**:

| Environment | Protection rules |
|---|---|
| `development` | None (deploys immediately) |
| `production` | Required reviewers — add at least one approver |

Without a `production` environment configured, prod deploys will run without an approval gate.
