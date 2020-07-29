# Bootstrapping Terraform

This solves a 🐓 and 🥚 problem in new AWS accounts (or for AWS accounts that have never used Terraform): How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* AWS Account Alias for the AWS account
* S3 bucket for remote state file (using the TrussWorks [s3-private-bucket module](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws))
* S3 bucket for storing state bucket access logs (using the TrussWorks [logs module](https://registry.terraform.io/modules/trussworks/logs/aws))
* DynamoDB table for state locking and consistency checking

If the AWS account you are using already has a Terraform state bucket and locking table, this may not be the right tool for you.

## Terraform Versions

Terraform 0.12. Pin module version to latest. Submit pull-requests to master branch.

## Usage for bootstrapping

```hcl
module "bootstrap" {
  source = "trussworks/bootstrap/aws"

  region        = "us-west-2"
  account_alias = "<ORG>-<NAME>"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_alias | The desired AWS account alias. | `string` | n/a | yes |
| region | AWS region. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_table | The name of the dynamo db table |
| logging\_bucket | The logging\_bucket name |
| state\_bucket | The state\_bucket name |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Bootstrapping

Create a new directory where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

If your `aws` commands run via [aws-vault](https://github.com/99designs/aws-vault) and you are using root credentials, you'll need to set the `--no-session` flag so the IAM operations can run without being MFA'd. If you're using the [Truss aws-vault-wrapper](https://github.com/trussworks/terraform-layout-example/blob/master/bin/aws-vault-wrapper) you can set the `AWS_VAULT_NO_SESSION` environment variable. If you don't do this you'll receive an `InvalidClientTokenId` error.

If you are running your `aws` commands via [aws-vault](https://github.com/99designs/aws-vault) and are using a role assumption, you will want to run this script without `AWS_VAULT_NO_SESSION`. The role assumption between different profiles requires session behavior. Additionally, this script will attempt to run `aws s3 ls` before checking for bucket existence so that you can create a session token that may require an MFA handshake.

Set up your `bootstrap/main.tf` file to look like the example above. Don't forget to include a `providers.tf` file that looks like this:

```hcl
provider "aws" {
  version = "~> 2.70.0"
  region  = local.region
}
```

Then run this like any other terraform module:

```sh
terraform init && terraform plan
# Review output of plan
terraform apply
```

The account alias will be configured (if not set), the resources will be created, and a state file will be generated. Commit the state file and the terraform code. Push those changes to your repo.

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
