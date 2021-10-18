module "bootstrap" {
  source = "../../"

  region               = "us-west-2"
  account_alias        = var.account_alias
  dynamodb_table_name  = var.dynamodb_table_name
  manage_account_alias = false
}