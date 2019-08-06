#
# Terraform state bucket
#

module "terraform_state_bucket" {
  source         = "trussworks/s3-private-bucket/aws"
  version        = "~> 1.7.0"
  bucket         = "${var.state_bucket}"
  logging_bucket = "${module.terraform_state_bucket_logs.aws_logs_bucket}"

  use_account_alias_prefix = false

  tags = {
    Automation = "Terraform"
  }
}

#
# Terraform state bucket logging
#

module "terraform_state_bucket_logs" {
  source  = "trussworks/logs/aws"
  version = "~> 3.4.0"
  region  = "${var.region}"

  s3_bucket_name = "${var.logging_bucket}"

  default_allow = false
}

#
# Terraform state locking
#

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 2
  write_capacity = 2

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name       = "terraform-state-lock"
    Automation = "Terraform"
  }
}
