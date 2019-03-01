variable "region" {
  description = "AWS region."
  type        = "string"
}

variable "state_bucket" {
  description = "S3 bucket to store Terraform state in ."
  type        = "string"
}

variable "logging_bucket" {
  description = "S3 bucket to send state_bucket access logs to."
  type        = "string"
}
