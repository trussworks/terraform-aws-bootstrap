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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.75.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.75.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| terraform\_state\_bucket | trussworks/s3-private-bucket/aws | ~> 4.3.0 |
| terraform\_state\_bucket\_logs | trussworks/logs/aws | ~> 14.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_state_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_account_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_alias) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_alias | The desired AWS account alias. | `string` | n/a | yes |
| bucket\_key\_enabled | Whether or not to use Amazon S3 Bucket Keys for SSE-KMS. | `bool` | `false` | no |
| bucket\_purpose | Name to identify the bucket's purpose | `string` | `"tf-state"` | no |
| dynamodb\_point\_in\_time\_recovery | Point-in-time recovery options | `bool` | `false` | no |
| dynamodb\_table\_name | Name of the DynamoDB Table for locking Terraform state. | `string` | `"terraform-state-lock"` | no |
| dynamodb\_table\_tags | Tags of the DynamoDB Table for locking Terraform state. | `map(string)` | ```{ "Automation": "Terraform", "Name": "terraform-state-lock" }``` | no |
| enable\_s3\_public\_access\_block | Bool for toggling whether the s3 public access block resource should be enabled. | `bool` | `true` | no |
| kms\_master\_key\_id | The AWS KMS master key ID used for the SSE-KMS encryption of the state bucket. | `string` | `null` | no |
| log\_bucket\_tags | Tags to associate with the bucket storing the Terraform state bucket logs | `map(string)` | ```{ "Automation": "Terraform" }``` | no |
| log\_bucket\_versioning | A string that indicates the versioning status for the log bucket. | `string` | `"Disabled"` | no |
| log\_name | Log name (for backwards compatibility this can be modified to logs) | `string` | `"log"` | no |
| log\_retention | Log retention of access logs of state bucket. | `number` | `90` | no |
| manage\_account\_alias | Manage the account alias as a resource. Set to 'false' if this behavior is not desired. | `bool` | `true` | no |
| region | AWS region. | `string` | n/a | yes |
| state\_bucket\_tags | Tags to associate with the bucket storing the Terraform state files | `map(string)` | ```{ "Automation": "Terraform" }``` | no |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_table | The name of the dynamo db table |
| logging\_bucket | The logging\_bucket name |
| state\_bucket | The state\_bucket name |
<!-- END_TF_DOCS -->

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

### Release v3.0.0

Version 3.x.x enables the use of version 4 of the AWS provider. Terraform provided [an upgrade path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade) for this. To support the upgrade path, this module now includes the following additional resources:

* `module.terraform_state_bucket.aws_s3_bucket_policy.private_bucket`
* `module.terraform_state_bucket.aws_s3_bucket_acl.private_bucket`
* `module.terraform_state_bucket.aws_s3_bucket_versioning.private_bucket`
* `module.terraform_state_bucket.aws_s3_bucket_lifecycle_configuration.private_bucket`
* `module.terraform_state_bucket.aws_s3_bucket_logging.private_bucket`
* `module.terraform_state_bucket.aws_s3_bucket_server_side_encryption_configuration.private_bucket`
* `module.terraform_state_bucket_logs.aws_s3_bucket_policy.aws_logs`
* `module.terraform_state_bucket_logs.aws_s3_bucket_acl.aws_logs`
* `module.terraform_state_bucket_logs.aws_s3_bucket_lifecycle_configuration.aws_logs`
* `module.terraform_state_bucket_logs.aws_s3_bucket_server_side_encryption_configuration.aws_logs`
* `module.terraform_state_bucket_logs.aws_s3_bucket_logging.aws_logs`
* `module.terraform_state_bucket_logs.aws_s3_bucket_versioning.aws_logs`

This module version changes the `log_bucket_versioning` variable from a boolean to a string. There are three possible values for this variable: `Enabled`, `Disabled`, and `Suspended`. If at one point versioning was enabled on your bucket, but has since been turned off, you will need to set `log_bucket_versioning` to `Suspended` rather than `Disabled`.

Additionally, this version of the module requires a minimum AWS provider version of 3.75, so that you can remain on the 3.x AWS provider while still gaining the ability to utilize the new S3 resources introduced in the 4.x AWS provider.

There are two general approaches to performing this upgrade:

1. Upgrade the module version and run `terraform plan` followed by `terraform apply`, which will create the new Terraform resources.
1. Perform `terraform import` commands, which accomplishes the same thing without running `terraform apply`. This is the more cautious route.

If you choose to take the route of running `terraform import`, you will need to perform the following imports. Replace `example` with the name you're using when calling this module and replace `your-bucket-name-here` with the name of your bucket (as opposed to an S3 bucket ARN). Replace `your-logging-bucket-name-here` with the name of your logging bucket. Also note the inclusion of `,private` when importing the new `module.terraform_state_bucket.aws_s3_bucket_acl.private_bucket` Terraform resource and the inclusion of `,log-delivery-write` when importing the new `module.terraform_state_bucket_logs.aws_s3_bucket_acl.aws_logs` Terraform resource.

```sh
terraform import module.example.module.terraform_state_bucket.aws_s3_bucket_policy.private_bucket your-bucket-name-here
terraform import module.example.module.terraform_state_bucket.aws_s3_bucket_acl.private_bucket your-bucket-name-here,private
terraform import module.example.module.terraform_state_bucket.aws_s3_bucket_versioning.private_bucket your-bucket-name-here
terraform import module.example.module.terraform_state_bucket.aws_s3_bucket_lifecycle_configuration.private_bucket your-bucket-name-here
terraform import module.example.module.terraform_state_bucket.aws_s3_bucket_server_side_encryption_configuration.private_bucket your-bucket-name-here
terraform import 'module.example.module.terraform_state_bucket.aws_s3_bucket_logging.private_bucket[0]' your-bucket-name-here
terraform import module.example.module.terraform_state_bucket_logs.aws_s3_bucket_policy.aws_logs your-logging-bucket-name-here
terraform import module.example.module.terraform_state_bucket_logs.aws_s3_bucket_acl.aws_logs your-logging-bucket-name-here,log-delivery-write
terraform import module.example.module.terraform_state_bucket_logs.aws_s3_bucket_lifecycle_configuration.aws_logs your-logging-bucket-name-here
terraform import module.example.module.terraform_state_bucket_logs.aws_s3_bucket_server_side_encryption_configuration.aws_logs your-logging-bucket-name-here
terraform import module.example.module.terraform_state_bucket_logs.aws_s3_bucket_versioning.aws_logs your-logging-bucket-name-here
```

After this, you will need to run a `terraform plan` and `terraform apply` to apply some non-functional changes to lifecycle rule IDs.

### Release v2.0.0

When upgrading from v1.6.1 to v2.0.0 the terraform state must be modified to move the account alias resource:

```sh
terraform state mv module.example.aws_iam_account_alias.alias module.example.aws_iam_account_alias.alias[0]
```

If you do not want to manage the account alias with this module you can instead use a data resource
to get the account alias and pass it into the module. Also set `manage_account_alias` to `false`.

```hcl
data "aws_iam_account_alias" "current" {}
module "bootstrap" {
  source = "trussworks/bootstrap/aws"

  region               = "us-west-2"
  account_alias        = data.aws_iam_account_alias.current.id
  manage_account_alias = false
}
```

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
