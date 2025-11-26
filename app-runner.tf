resource "aws_iam_role" "app_runner_service_role" {
  name = "app-runner-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "AppRunnerServiceRole"
    Environment = var.env
  }
}

resource "aws_iam_role" "app_runner_ssm_role" {
  name = "${var.env}_apprunner_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ssm_read_policy" {
  name        = "${var.env}_apprunner_SSMReadPolicy"
  description = "Allow App Runner to read SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = "arn:aws:ssm:eu-west-2:${var.aws_account}:parameter/schoolsmart/*"
    }]
  })
}

resource "aws_iam_policy" "s3_read_write_policy" {
  name        = "${var.env}_apprunner_S3ReadWrite"
  description = "Allow App Runner to read and write S3 documents"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      Resource = "arn:aws:s3:::${var.app_runner_environment_variables.S3_BUCKET}/*"
    }]
  })
}

resource "aws_iam_policy" "dynamodb_read_write_policy" {
  name        = "${var.env}_apprunner_DynamoDBReadWrite"
  description = "Allow App Runner to read and write DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "dynamodb:BatchGetItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "ses_send_email_policy" {
  name        = "${var.env}_apprunner_SESSendEmail"
  description = "Allow App Runner to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_access" {
  role       = aws_iam_role.app_runner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role_policy_attachment" "app_runner_ssm_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_s3_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_dynamodb_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.dynamodb_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_ses_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.ses_send_email_policy.arn
}

resource "aws_apprunner_service" "app_server" {
  service_name = "app-server-${var.env}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_service_role.arn
    }

    image_repository {
      image_configuration {
        port = var.app_runner_port
        runtime_environment_variables = var.app_runner_environment_variables
      }
      image_identifier      = "${var.app_runner_ecr_repo_url}:${var.app_runner_image_tag}"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = var.app_runner_auto_deployments_enabled
  }

  instance_configuration {
    cpu    = var.app_runner_cpu
    memory = var.app_runner_memory
    instance_role_arn = aws_iam_role.app_runner_ssm_role.arn
  }

  tags = {
    Name        = "AppServer"
    Environment = var.env
  }
}
