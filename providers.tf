provider "aws" {
  version = "~> 1.41.0"
  region  = "${var.region}"
}

provider "template" {
  version = "~> 1.0.0"
}
