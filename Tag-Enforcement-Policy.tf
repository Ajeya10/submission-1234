# main.tf for Governance
resource "aws_organizations_policy" "tagging_policy" {
  name        = "tagging-compliance-policy"
  description = "Requires specific tags on all resources"

  content = <<CONTENT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/Project": "true",
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Owner": "true"
        }
      }
    }
  ]
}
CONTENT
}

resource "aws_config_configuration_recorder" "atlan" {
  name     = "atlan-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "atlan" {
  name           = "atlan-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.atlan]
}

resource "aws_resourcegroups_group" "production" {
  name = "production-resources"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": ["AWS::AllSupported"],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["production"]
    }
  ]
}
JSON
  }
}
## Organization Structure: These scripts assume you have AWS Organizations set up. For SCPs to work, you must be the management account.
