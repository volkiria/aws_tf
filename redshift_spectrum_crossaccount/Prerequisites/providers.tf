provider "aws" {
  alias = "redshift_account"

  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      Environment = var.environment
      Purpose     = "Redshift Spectrum Demo"
    }
  }
}