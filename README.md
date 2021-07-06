# Bootstrapping Terraform

This solves a 🐓 and 🥚 problem in new AWS accounts (or for AWS accounts that have never used Terraform): How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages these resources:

* AWS Account Alias for the AWS account
* S3 bucket for remote state file (using the TrussWorks [s3-private-bucket module](https://registry.terraform.io/modules/trussworks/s3-private-bucket/aws))
* S3 bucket for storing state bucket access logs (using the TrussWorks [logs module](https://registry.terraform.io/modules/trussworks/logs/aws))
* DynamoDB table for state locking and consistency checking

If the AWS account you are using already has a Terraform state bucket and locking table, this may not be the right tool for you.

## Terraform Versions

Terraform 0.13 and higher. Pin module version to latest. Submit pull-requests to master branch.

Terraform 0.12. Pin module version to v0.1.4. Submit pull-requests to terraform012 branch.

## Usage for bootstrapping

```hcl
module "bootstrap" {
  source = "trussworks/bootstrap/aws"

  region        = "us-west-2"
  account_alias = "<ORG>-<NAME>"
}
```

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_terraform_state_bucket"></a> [terraform\_state\_bucket](#module\_terraform\_state\_bucket) | trussworks/s3-private-bucket/aws | ~> 3.6.0 |
| <a name="module_terraform_state_bucket_logs"></a> [terraform\_state\_bucket\_logs](#module\_terraform\_state\_bucket\_logs) | trussworks/logs/aws | ~> 10.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_state_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_account_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_alias) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_alias"></a> [account\_alias](#input\_account\_alias) | The desired AWS account alias. | `string` | n/a | yes |
| <a name="input_bucket_purpose"></a> [bucket\_purpose](#input\_bucket\_purpose) | Name to identify the bucket's purpose | `string` | `"tf-state"` | no |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | Name of the DynamoDB Table for locking Terraform state. | `string` | `"terraform-state-lock"` | no |
| <a name="input_dynamodb_table_tags"></a> [dynamodb\_table\_tags](#input\_dynamodb\_table\_tags) | Tags of the DynamoDB Table for locking Terraform state. | `map(string)` | <pre>{<br>  "Automation": "Terraform",<br>  "Name": "terraform-state-lock"<br>}</pre> | no |
| <a name="input_enable_s3_public_access_block"></a> [enable\_s3\_public\_access\_block](#input\_enable\_s3\_public\_access\_block) | Bool for toggling whether the s3 public access block resource should be enabled. | `bool` | `true` | no |
| <a name="input_log_bucket_versioning"></a> [log\_bucket\_versioning](#input\_log\_bucket\_versioning) | Bool for toggling versioning for log bucket | `bool` | `false` | no |
| <a name="input_log_name"></a> [log\_name](#input\_log\_name) | Log name (for backwards compatibility this can be modified to logs) | `string` | `"log"` | no |
| <a name="input_log_retention"></a> [log\_retention](#input\_log\_retention) | Log retention of access logs of state bucket. | `number` | `90` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | n/a | yes |
| <a name="input_state_bucket_tags"></a> [state\_bucket\_tags](#input\_state\_bucket\_tags) | Tags to associate with the bucket storing the Terraform state files | `map(string)` | <pre>{<br>  "Automation": "Terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table"></a> [dynamodb\_table](#output\_dynamodb\_table) | The name of the dynamo db table |
| <a name="output_logging_bucket"></a> [logging\_bucket](#output\_logging\_bucket) | The logging\_bucket name |
| <a name="output_state_bucket"></a> [state\_bucket](#output\_state\_bucket) | The state\_bucket name |

<!--- END_TF_DOCS --->

## Bootstrapping

Create a new directory where your Terraform config will live. For example, it could live in a directory like `terraform/account-alias/bootstrap`.

If your `aws` commands run via [aws-vault](https://github.com/99designs/aws-vault) and you are using root credentials, you'll need to set the `--no-session` flag so the IAM operations can run without being MFA'd. If you're using the [Truss aws-vault-wrapper](https://github.com/trussworks/terraform-layout-example/blob/master/bin/aws-vault-wrapper) you can set the `AWS_VAULT_NO_SESSION` environment variable. If you don't do this you'll receive an `InvalidClientTokenId` error.

If you are running your `aws` commands via [aws-vault](https://github.com/99designs/aws-vault) and are using a role assumption, you will want to run this script without `AWS_VAULT_NO_SESSION`. The role assumption between different profiles requires session behavior. Additionally, this script will attempt to run `aws s3 ls` before checking for bucket existence so that you can create a session token that may require an MFA handshake.

Set up your `bootstrap/main.tf` file to look like the example above. Don't forget to include a `providers.tf` file that looks like this:

```hcl
provider "aws" {
  version = "~> 3.0"
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

## Contributing

To submit a PR, fork the repo and enable Github Actions. Enabling Github Actions is necessary to update terraform docs. To enable Github Actions, navigate to the actions tab in the forked repo. This step must be done manually - Github will not automatically enable this.

## Using the backend

After provisioning the S3 bucket and the DynamoDB table, you need to tell Terraform that it exists and to use it. You do so by defining a backend. You can create a file called `terraform.tf` in your directory's root.

```hcl
terraform {
  required_version = "~> 0.13"

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

## Upgrade Path

### Pre-module release to v0.1.1

To update from the pre-module release code that cloned this repo to the module release you'll need to do a few things:

1. Remove files that are no longer needed:

```sh
rm -f README.md bootstrap terraform.tfvars variables.tf versions.tf
```

1. Modify the `main.tf` to look like this:

```hcl
locals {
  region = "us-west-2"
}

module "bootstrap" {
  source  = "trussworks/bootstrap/aws"
  version = "~> 0.1.1"

  account_alias = "<ORG>-<NAME>"
  region        = local.region
}
```

1. Modify the `providers.tf` to look like this:

```hcl
provider "aws" {
  version = "~> 2.70.0"
  region  = local.region
}
```

1. Re-initialize the module and then get the terraform plan:


```sh
terraform init
terraform plan
```

1. Import the AWS account alias and then move the terraform state to the new namespaces.

```sh
terraform import module.bootstrap.aws_iam_account_alias.alias trussworks-cgilmer
terraform state mv aws_dynamodb_table.terraform_state_lock module.bootstrap.aws_dynamodb_table.terraform_state_lock
terraform state mv module.terraform_state_bucket.aws_s3_bucket.private_bucket module.bootstrap.module.terraform_state_bucket.aws_s3_bucket.private_bucket
terraform state mv module.terraform_state_bucket.aws_s3_bucket_analytics_configuration.private_analytics_config[0] module.bootstrap.module.terraform_state_bucket.aws_s3_bucket_analytics_configuration.private_analytics_config[0]
terraform state mv module.terraform_state_bucket.aws_s3_bucket_public_access_block.public_access_block module.bootstrap.module.terraform_state_bucket.aws_s3_bucket_public_access_block.public_access_block
terraform state mv module.terraform_state_bucket_logs.aws_s3_bucket.aws_logs module.bootstrap.module.terraform_state_bucket_logs.aws_s3_bucket.aws_logs
terraform state mv module.terraform_state_bucket_logs.aws_s3_bucket_public_access_block.public_access_block[0] module.bootstrap.module.terraform_state_bucket_logs.aws_s3_bucket_public_access_block.public_access_block[0]
```

1. Verify the changes result in no modification to the terraform plan:

```sh
terraform plan
```

Output should look like this if you are successful:

```text
No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

1. Finally, commit your code and create a PR.

```sh
git checkout -b update_bootstrap_for_<ORG>_<NAME>
git commit -am"Update the bootstrap stack to use the bootstrap terraform module"
```
