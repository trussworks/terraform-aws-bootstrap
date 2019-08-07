# Bootstrapping Terraform

This solves a 🐓 and 🥚 problem in new AWS accounts (or for AWS accounts that have never used Terraform): How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* S3 bucket for remote state file (using the TrussWorks [s3-private-bucket module](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws))
* S3 bucket for storing state bucket access logs (using the TrussWorks [logs module](https://registry.terraform.io/modules/trussworks/logs/aws))
* DynamoDB table for state locking and consistency checking

If the AWS account you are using already has a Terraform state bucket and locking table, this may not be the right tool for you.

## Bootstrapping

Copy the code in this repo to where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

If your `aws` commands run via [aws-vault](https://github.com/99designs/aws-vault), you'll need to set the `--no-session` flag so the IAM operations can run without being MFA'd. If you're using the [Truss aws-vault-wrapper](https://github.com/trussworks/terraform-layout-example/blob/master/bin/aws-vault-wrapper) you can set the `AWS_VAULT_NO_SESSION` environment variable. If you don't do this you'll receive an `InvalidClientTokenId` error.

Run the `bootstrap` script, specifying your AWS account alias and region:

```sh
./bootstrap my-account-alias us-west-2
```

The account alias will be configured (if not set), the resources will be created, and a git commit will be made with the tfvars and state files. Push those changes to your repo.

## Pre-existing environments

The code can be customized for specific environments. For example, if you're bootstrapping Terraform into an existing environment, you may want to use an existing logging bucket for the S3 logs. Edit the Terraform and bootstrap script as you need.

## Subsequent changes

The `bootstrap` script should only be used for the initial setup. If you need to make any changes to the Terraform code (e.g. adding capacity to DynamoDB), follow your typical development processes for the code changes. Remember to commit the statefile after you apply the changes!
