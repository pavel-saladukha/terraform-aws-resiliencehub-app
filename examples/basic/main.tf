#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.20"
    }

  }

  required_version = ">= 0.14.9"

}

terraform {
  backend "s3" {
    bucket         = "tf-state-rhub"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-bucket-key"
    dynamodb_table = "terraform-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "awscc" {
  region = "us-east-1"
}

locals {
  bucket_name   = "tf-state-rhub"
  path_to_state = "state/terraform.tfstate"
}

resource "aws_kms_key" "terraform-bucket-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/terraform-bucket-key"
  target_key_id = aws_kms_key.terraform-bucket-key.key_id
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_policy" "s3_rhub_state_policy" {
  bucket = aws_s3_bucket.terraform-state.id
  policy = data.aws_iam_policy_document.rhub_access.json
}

data "aws_iam_policy_document" "rhub_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.rhub_role.arn}"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.terraform-state.arn,
      "${aws_s3_bucket.terraform-state.arn}/${local.path_to_state}",
    ]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-state" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
    }
  }
}

resource "aws_dynamodb_table" "terraform-state" {
  name           = "terraform-state"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "awscc_resiliencehub_app" "rhub" {

  # Required
  name = "rhub-manual-1"
  app_template_body = jsonencode(
    {
    }
  )
  resource_mappings = [
    {
      mapping_type = "Terraform"
      physical_resource_id = {
        identifier = "s3://${local.bucket_name}/${local.path_to_state}"
        type       = "Native"
      }
      terraform_source_name = "terraform.tfstate"
    },
  ]

  # Optional
  app_assessment_schedule = "Disabled"
  permission_model = {
    invoker_role_name = "rhub_role"
    type              = "RoleBased"
  }

  # resiliency_policy_arn = data.aws_iam_policy.rhub-managed-policy.arn
}

resource "aws_iam_role" "rhub_role" {
  name = "rhub_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow"
        "Sid" : ""
        "Principal" : {
          "Service" : "resiliencehub.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy" "rhub-managed-policy" {
  name = "AWSResilienceHubAsssessmentExecutionPolicy"
}

resource "aws_iam_policy" "rhub_policy" {
  name        = "rhub_policy"
  path        = "/"
  description = "rhub policy"

  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${local.bucket_name}/${local.path_to_state}"
      },
      {
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::${local.bucket_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
        ],
        "Resource" : aws_kms_key.terraform-bucket-key.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeTable",
        ],
        "Resource" : aws_dynamodb_table.terraform-state.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rhub-attach" {
  role       = aws_iam_role.rhub_role.name
  policy_arn = aws_iam_policy.rhub_policy.arn
}

resource "aws_iam_role_policy_attachment" "rhub-managed-attach" {
  role       = aws_iam_role.rhub_role.name
  policy_arn = data.aws_iam_policy.rhub-managed-policy.arn
}
