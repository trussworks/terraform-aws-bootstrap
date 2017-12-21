# Bootstrapping Terraform

This manages the 🐓 and 🥚 problem: How do you Terraform the remote state bucket? It takes the approach of keeping a local statefile in the repo that only manages that one bucket.

The bootstrapper does the following:

* Sets the IAM Account Alias (required by the `s3-private-bucket` module)
* Creates the Terraform state bucket

To bootstrap a new account, you'll need to create access keys for the root account and either set them as environment variables or configure a profile. Once set, the `bootstrap.sh` can be run. It should only be run once.
