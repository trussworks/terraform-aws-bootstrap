#
# Create Terraform state bucket
#

module "terraform-state-bucket" {
  source         = "trussworks/s3-private-bucket/aws"
  version        = "~> 1.5.0"
  bucket         = "terraform-state-${var.region}"
  logging_bucket = "${var.logging_bucket}"
}

#
# Create Terraform locking table
#

resource "aws_dynamodb_table" "terraform-state-lock" {
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

  tags {
    Name       = "terraform-state-lock"
    Automation = "Terraform"
  }
}
