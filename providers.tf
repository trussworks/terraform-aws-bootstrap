provider "aws" {
  version = "~> 1.6"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0"
}
