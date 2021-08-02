variable "dynamodb_table_names" {
  description = "Name of the DynamoDB Table for locking Terraform state."
  default     = "terraform-state-lock"
  type        = string
}

variable "dynamodb_table_namess" {
  description = "Name of the DynamoDB Table for locking Terraform state."
  default     = "terraform-state-lock"
  type        = string
}

variable "dynamodb_table_namesss" {
  description = "Name of the DynamoDB Table for locking Terraform state."
  default     = "terraform-state-lock"
  type        = string
}

variable "dynamodb_table_tags" {
  description = "Tags of the DynamoDB Table for locking Terraform state."
  default = {
    Name       = "terraform-state-lock"
    Automation = "Terraform"
  }
  type = map(string)
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "account_alias" {
  description = "The desired AWS account alias."
  type        = string
}

variable "log_retention" {
  description = "Log retention of access logs of state bucket."
  default     = 90
  type        = number
}

variable "bucket_purpose" {
  description = "Name to identify the bucket's purpose"
  default     = "tf-state"
  type        = string
}

variable "log_name" {
  description = "Log name (for backwards compatibility this can be modified to logs)"
  default     = "log"
  type        = string
}

variable "log_bucket_versioning" {
  description = "Bool for toggling versioning for log bucket"
  type        = bool
  default     = false
}

variable "state_bucket_tags" {
  type        = map(string)
  default     = { Automation : "Terraform" }
  description = "Tags to associate with the bucket storing the Terraform state files"
}

variable "enable_s3_public_access_block" {
  description = "Bool for toggling whether the s3 public access block resource should be enabled."
  type        = bool
  default     = true
}
