module "bootstrap" {
  source = "../../"

  region = "us-west-2"
  account_alias = var.account_alias
}