provider "aws" {
  version = "~> 2.54"
  region  = var.region
}

provider "template" {
  version = "~> 2.1"
}

