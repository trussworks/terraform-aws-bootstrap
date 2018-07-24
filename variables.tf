variable "region" {
  description = "AWS region."
  type        = "string"
}

variable "logging_bucket" {
  description = "S3 bucket to send S3 access logs."
  type        = "string"
}
