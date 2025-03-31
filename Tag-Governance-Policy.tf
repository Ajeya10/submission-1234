# governance/main.tf

# 1. Create AWS Organization
resource "aws_organizations_organization" "ajeya" {
  aws_service_access_principals = [
    "config.amazonaws.com",
    "sso.amazonaws.com"
  ]
  feature_set = "ALL"
}

# 2. Create S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "config-logs-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Purpose = "aws-config-logs"
  }
}

# 3. Create Config delivery channel
resource "aws_config_delivery_channel" "default" {
  name           = "config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.default]
}

# 4. Create Config recorder
resource "aws_config_configuration_recorder" "default" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# 5. IAM role for Config
resource "aws_iam_role" "config" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# 6. IAM policy for Config
resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# 7. SCP for Tag Enforcement (after organization exists)
resource "aws_organizations_policy" "tag_policy" {
  depends_on = [aws_organizations_organization.ajeya]
  
  name        = "ajeya-tag-policy"
  description = "Requires specific tags on all resources"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny",
        Action   = "*",
        Resource = "*",
        Condition = {
          Null = {
            "aws:RequestTag/Project"     = "true",
            "aws:RequestTag/Environment" = "true",
            "aws:RequestTag/Owner"       = "true"
          }
        }
      }
    ]
  })
}

# 8. Resource Groups
resource "aws_resourcegroups_group" "production" {
  name = "production-resources-group"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        {
          Key    = "Environment",
          Values = ["production"]
        }
      ]
    })
  }
}

data "aws_caller_identity" "current" {}
