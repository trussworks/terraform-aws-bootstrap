# Create Terraform state bucket
# -----------------------------

module "terraform-state-bucket" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 1.3"
  bucket  = "terraform-state-${var.region}"
}

# Create Terraform locking table
# ------------------------------

resource "aws_dynamodb_table" "terraform-state-lock" {
  name           = "terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "terraform-state-lock"
  }
}
