resource "aws_iam_role" "app_runner_deployment_role" {
  name = "${var.env}-app-runner-deployment-role"

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
    Name        = "AppRunnerDeploymentRole"
    Environment = var.env
  }
}

resource "aws_iam_role" "app_runner_instance_role" {
  name = "${var.env}-app-runner-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# resource "aws_iam_policy" "ssm_read_policy" {
#   name        = "${var.env}-apprunner-SSMReadPolicy"
#   description = "Allow App Runner to read SSM parameters"
#
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect   = "Allow",
#       Action   = [
#         "ssm:GetParameter",
#         "ssm:GetParameters",
#         "ssm:GetParametersByPath"
#       ],
#       Resource = "arn:aws:ssm:eu-west-2:${var.aws_account}:parameter/schoolsmart/*"
#     }]
#   })
# }

resource "aws_iam_policy" "s3_read_write_policy" {
  name        = "${var.env}-apprunner-S3ReadWrite"
  description = "Allow App Runner to read and write S3 documents"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      Resource = "arn:aws:s3:::${local.invoice_bucket_name}/*"
    }]
  })
}

resource "aws_iam_policy" "dynamodb_read_write_policy" {
  name        = "${var.env}-apprunner-DynamoDBReadWrite"
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

resource "aws_iam_policy" "ses_assume_role_policy" {
  name        = "${var.env}-apprunner-SESAssumeRole"
  description = "Allow App Runner to assume role in shared account to send email"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Resource = "arn:aws:iam::${var.shared_services_account_id}:role/CrossAccountSESSendRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_access" {
  role       = aws_iam_role.app_runner_deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# resource "aws_iam_role_policy_attachment" "app_runner_ssm_access" {
#   role       = aws_iam_role.app_runner_instance_role.name
#   policy_arn = aws_iam_policy.ssm_read_policy.arn
# }

resource "aws_iam_role_policy_attachment" "app_runner_s3_access" {
  role       = aws_iam_role.app_runner_instance_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_dynamodb_access" {
  role       = aws_iam_role.app_runner_instance_role.name
  policy_arn = aws_iam_policy.dynamodb_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "assume_ses_assume_role_policy" {
  role = aws_iam_role.app_runner_instance_role.id
  policy_arn = aws_iam_policy.ses_assume_role_policy.arn
}

resource "aws_iam_role_policy" "app_runner_ecr_access" {
  role = aws_iam_role.app_runner_deployment_role.name
  name = "ECRAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages"
        ]
        Resource = data.aws_ecr_repository.shared_ecr.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_apprunner_service" "api_server" {
  service_name = "${var.env}-api-server"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_deployment_role.arn
    }

    image_repository {
      image_configuration {
        port = var.app_runner_port
        runtime_environment_variables = local.app_runner_env_vars
      }
      image_identifier      = "${var.app_runner_ecr_repo_url}:${var.app_runner_image_tag}"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = var.app_runner_cpu
    memory = var.app_runner_memory
    instance_role_arn = aws_iam_role.app_runner_instance_role.arn
  }

  tags = {
    Name        = "AppServer"
    Environment = var.env
  }
}
