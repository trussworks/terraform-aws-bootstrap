provider "aws" {
  version = "~> 1.11.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
