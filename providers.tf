provider "aws" {
  version = "~> 2.43.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 2.1.2"
}
