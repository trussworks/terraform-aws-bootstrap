provider "aws" {
  version = "~> 2.18.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 2.1.0"
}
