# Create Terraform state bucket
# -----------------------------

module "terraform-state-bucket" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 1.3"
  bucket  = "terraform-state-${var.region}"
}
