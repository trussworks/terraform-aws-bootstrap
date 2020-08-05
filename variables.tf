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
  default = 731
  type        = number
}
