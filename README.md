# Bootstrapping Terraform

This solves the 🐓 and 🥚 problem: How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* S3 bucket for remote state file (using the [s3-private-bucket](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws) module)
* DynamoDB table for state locking and consistency checking

## Bootstrapping

Copy the code in this repo to where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

Run the `bootstrap` script, specifying your AWS account alias and region:

```text
./bootstrap my-account-alias us-west-2
```

The account alias will configured (if not set), the resources will be created, and a git commit will be made with the region and statefile. Push those changes to your repo.

## Subsequent changes

The `bootstrap` script should only be used for the initial setup. If you need to make any changes to the Terraform code (e.g. adding capacity to DynamoDB), follow your typical development processes for the code changes. Remember to commit the statefile after you apply the changes!
