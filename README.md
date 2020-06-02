# Bootstrapping Terraform

This solves a 🐓 and 🥚 problem in new AWS accounts (or for AWS accounts that have never used Terraform): How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* S3 bucket for remote state file (using the TrussWorks [s3-private-bucket module](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws))
* S3 bucket for storing state bucket access logs (using the TrussWorks [logs module](https://registry.terraform.io/modules/trussworks/logs/aws))
* DynamoDB table for state locking and consistency checking

If the AWS account you are using already has a Terraform state bucket and locking table, this may not be the right tool for you.

## Bootstrapping

Copy the code in this repo to where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

You'll need to follow our [AWS Account Structure](https://github.com/trussworks/legendary-waddle/blob/master/README.md#aws-account-structure) to create an account alias. Make sure you're accessesing the existing `OrganizationAccountAccessRole` to bootstrap your account. The profile in your `.aws/config` should look something like this:

```sh
[profile trussworks-rosa]
source_profile=trussworks-org-root
mfa_serial=arn:aws:iam::11111111111:mfa/rosa.org-root
role_arn=arn:aws:iam::22222222222:role/OrganizationAccountAccessRole
region=us-west-2
output=json
```

If your `aws` commands run via [aws-vault](https://github.com/99designs/aws-vault) and you are using root credentials, you'll need to set the `--no-session` flag so the IAM operations can run without being MFA'd. If you're using the [Truss aws-vault-wrapper](https://github.com/trussworks/terraform-layout-example/blob/master/bin/aws-vault-wrapper) you can set the `AWS_VAULT_NO_SESSION` environment variable. If you don't do this you'll receive an `InvalidClientTokenId` error.

```sh
AWS_VAULT_NO_SESSION=true
```

If you are running your `aws` commands via [aws-vault](https://github.com/99designs/aws-vault) and are using a role assumption, you will want to run this script without `AWS_VAULT_NO_SESSION`. The role assumption between different profiles requires session behavior. Additionally, this script will attempt to run `aws s3 ls` before checking for bucket existence so that you can create a session token that may require an MFA handshake.

Run the `bootstrap` script, specifying your AWS account alias and region:

```sh
./bootstrap my-account-alias region
```

The account alias will be configured (if not set), the resources will be created, and a git commit will be made with the tfvars and state files. Push those changes to your repo.

## Pre-existing environments

The code can be customized for specific environments. For example, if you're bootstrapping Terraform into an existing environment, you may want to use an existing logging bucket for the S3 logs. Edit the Terraform and bootstrap script as you need.

## Subsequent changes

The `bootstrap` script should only be used for the initial setup. If you need to make any changes to the Terraform code (e.g. adding capacity to DynamoDB), follow your typical development processes for the code changes. Remember to commit the statefile after you apply the changes!

## Using the backend

After provisioning the S3 bucket and the DynamoDB table, you need to tell Terraform that it exists and to use it. You do so by defining a backend. You can create a file called `terraform.tf` in your directory's root.

```hcl
terraform {
  required_version = "~> 0.12"

  backend "s3" {
    bucket         = "bucket-name"
    key            = "path-to/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    region         = "region"
    encrypt        = "true"
  }
}
```

`bucket` exists in the generated `$tfvars_file` from the `bootstrap` script's execution. Region also exists in that file or you passed it in the initial execution of the `bootstrap` script. The `key` is the path to the `terraform.tfstate` from the execution of the `bootstrap` script.
