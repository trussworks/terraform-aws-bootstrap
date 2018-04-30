provider "aws" {
  version = "~> 1.16.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
