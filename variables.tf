variable "app_components" {
  type = list(object({
    app_component_name = string
    app_component_type = string
    resources = list(object({
      resource_name            = string
      resource_type            = string
      resource_identifier      = string
      resource_identifier_type = string
      resource_region          = string
    }))
  }))

  description = "The application's app-components, including its resources"
}

variable "app_name" {
  type        = string
  description = "The Application's name"
}

variable "s3_state_file_url" {
  type        = string
  description = "An URL to s3-backend Terraform state-file"
}

variable "rto" {
  type        = number
  description = "RTO across all failure metrics"
}

variable "rpo" {
  type        = number
  description = "RPO across all failure metrics"
}

# resource "awscc_resiliencehub_app" "rhub" {
#     app_arn                 = "arn:aws:resiliencehub:us-east-1:account_id:app/528b37e9-d9e3-4780-a7ca-bd4cd9665c73"
#     app_assessment_schedule = "Disabled"
#     app_template_body       = jsonencode(
#         {
#             appComponents     = [
#                 {
#                     id            = "StorageAppComponent-S3Bucket-terraform-stateaws_s3_buc"
#                     name          = "StorageAppComponent-S3Bucket-terraform-stateaws_s3_buc"
#                     resourceNames = [
#                         "s3bucket",
#                     ]
#                     type          = "AWS::ResilienceHub::StorageAppComponent"
#                 },
#                 {
#                     id            = "DatabaseAppComponent-DynamoDBTable-terraform-state"
#                     name          = "DatabaseAppComponent-DynamoDBTable-terraform-state"
#                     resourceNames = [
#                         "dynamodbtable",
#                     ]
#                     type          = "AWS::ResilienceHub::DatabaseAppComponent"
#                 },
#                 {
#                     id            = "appcommon"
#                     name          = "appcommon"
#                     resourceNames = []
#                     type          = "AWS::ResilienceHub::AppCommonAppComponent"
#                 },
#             ]
#             excludedResources = {
#                 logicalResourceIds = []
#             }
#             resources         = [
#                 {
#                     logicalResourceId = {
#                         identifier          = "terraform-state::aws_s3_bucket"
#                         logicalStackName    = null
#                         resourceGroupName   = null
#                         terraformSourceName = "terraform.tfstate"
#                     }
#                     name              = "s3bucket"
#                     type              = "AWS::S3::Bucket"
#                 },
#                 {
#                     logicalResourceId = {
#                         identifier          = "terraform-state"
#                         logicalStackName    = null
#                         resourceGroupName   = null
#                         terraformSourceName = "terraform.tfstate"
#                     }
#                     name              = "dynamodbtable"
#                     type              = "AWS::DynamoDB::Table"
#                 },
#             ]
#             version           = 2.0
#         }
#     )
#     drift_status            = "NotDetected"
#     id                      = "arn:aws:resiliencehub:us-east-1:account_id:app/528b37e9-d9e3-4780-a7ca-bd4cd9665c73"
#     name                    = "rhub-manual-1"
#     permission_model        = {
#         invoker_role_name = "rhub_role"
#         type              = "RoleBased"
#     }
#     resiliency_policy_arn   = "arn:aws:resiliencehub:us-east-1:account_id:resiliency-policy/b0cb4a2e-a700-496f-b9ed-b6849dcacba5"
#     resource_mappings       = [
#         {
#             mapping_type          = "Terraform"
#             physical_resource_id  = {
#                 identifier = "s3://tf-state-rhub/state/terraform.tfstate"
#                 type       = "Native"
#             }
#             terraform_source_name = "terraform.tfstate"
#         },
#     ]
#     tags                    = {}
# }
