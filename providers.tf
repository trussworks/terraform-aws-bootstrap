provider "aws" {
  version = "~> 1.7.1"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
