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

## First-time setup

### 1. AWS credentials

Add the following as repository secrets (or environment-level secrets for per-env isolation):

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key with permissions to apply Terraform |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |

The IAM user / role must be able to assume the roles referenced in `main.tf` (`local.account_role_arn`, `shared_services_account_id` roles).

### 2. GitHub Environments

Create two environments in **Settings → Environments**:

| Environment | Protection rules |
|---|---|
| `development` | None (deploys immediately) |
| `production` | Required reviewers — add at least one approver |

Without a `production` environment configured, prod deploys will run without an approval gate.

## Future: OIDC authentication

The current setup uses long-lived IAM credentials stored as secrets. Migrating to OIDC (AWS → GitHub) eliminates the need for stored credentials. This is tracked separately.
