provider "aws" {
  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      environment = var.environment
      purpose     = "Kong Demo"
    }
  }
}

provider "tls" {}