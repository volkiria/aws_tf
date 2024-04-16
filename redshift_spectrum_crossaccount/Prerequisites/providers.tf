provider "aws" {
  alias = "redshift_account"

  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      environment = var.environment
      purpose     = "Redshift Spectrum Demo"
    }
  }
}