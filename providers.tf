provider "aws" {
  version = "~> 1.19.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
