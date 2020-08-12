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
