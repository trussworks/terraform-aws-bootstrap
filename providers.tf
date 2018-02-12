provider "aws" {
  version = "~> 1.9.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
