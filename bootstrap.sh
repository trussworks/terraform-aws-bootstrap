#!/bin/bash
#
#   For brand new AWS accounts, this script will configure the account alias
#   prior to applying Terraform. It will only run if the alias and bucket do
#   not exist.
#
set -e -o pipefail

usage() {
    echo "Usage: $0 <account-alias> <region>"
    exit 1
}
[[ -z $1 || -z $2 ]] && usage
set -u

readonly account_alias=$1
readonly region=$2

readonly bucket=${account_alias}-terraform-state-${region}
readonly tfvars_file="terraform.tfvars"

# Bail out if any account alias already exists
current_alias=$(aws iam list-account-aliases --query 'AccountAliases' --output text)
if [[ -n $current_alias ]]; then
    echo "This account already has the alias '$current_alias' set!"
    exit 1
fi

# Bail out if the bucket already exists
status=$(aws s3 ls s3://$bucket/ 2>&1 | grep -o 'bucket does not exist') || true
if [[ $status != 'bucket does not exist' ]]; then
    set +x
    echo -e '\nLooks like the bucket '$bucket' already exists!'
    exit 1
fi

# Set account alias (required for bucket creation)
aws iam create-account-alias --account-alias $account_alias

# Generate terraform.tfvars with the chosen AWS region
echo "region = \"$region\"" > ${tfvars_file}

# Use Terraform with local state to create state bucket
terraform init
terraform apply -auto-approve

echo "Please commit the changes to $tfvars_file to complete the bootstrap process."
