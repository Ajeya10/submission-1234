resource "aws_organizations_policy" "tagging_policy" {
  name        = "enforce-mandatory-tags"
  description = "Requires mandatory tags on all resources"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EnforceMandatoryTags",
        Effect = "Deny",
        Action = "*",
        Resource = "*",
        Condition = {
          Null = {
            "aws:RequestTag/Environment" = "true",
            "aws:RequestTag/Owner"       = "true",
            "aws:RequestTag/Project"    = "true"
          }
        }
      }
    ]
  })
}
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "Prod"
      Owner       = "DataTeam"
      Project     = "Atlan-Infra"
      ManagedBy   = "Terraform"  # Auto-added to all resources
    }
  }
}
