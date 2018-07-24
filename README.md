# Bootstrapping Terraform

This solves the 🐓 and 🥚 problem: How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* S3 bucket for remote state file (using the [s3-private-bucket](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws) module)
* DynamoDB table for state locking and consistency checking

## Caveats

The current version of the [s3-private-bucket](https://github.com/trussworks/terraform-aws-s3-private-bucket) module expects a logging bucket to be specified. If you're on a greenfield project without that bucket yet, you can change `main.tf` to use v1.4.0 of the module and drop the `logging_bucket` parameter:

```hcl
module "terraform-state-bucket" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 1.4.0"
  bucket  = "terraform-state-${var.region}"
}
```

When invoking the `bootstrap` script, specify a dummy logging bucket parameter.

We hope to [fix this](https://github.com/trussworks/terraform-aws-s3-private-bucket/issues/8) in a future version.

## Bootstrapping

Copy the code in this repo to where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

Run the `bootstrap` script, specifying your AWS account alias, region, and logging bucket:

```text
./bootstrap my-account-alias us-west-2 my-aws-logging-bucket
```

The account alias will configured (if not set), the resources will be created, and a git commit will be made with the region and statefile. Push those changes to your repo.

## Subsequent changes

The `bootstrap` script should only be used for the initial setup. If you need to make any changes to the Terraform code (e.g. adding capacity to DynamoDB), follow your typical development processes for the code changes. Remember to commit the statefile after you apply the changes!
