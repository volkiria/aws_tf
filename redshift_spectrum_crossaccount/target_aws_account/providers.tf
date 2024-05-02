provider "aws" {
  alias   = "glue_account"
  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      environment = var.environment
      purpose     = "Redshift Spectrum Demo"
    }
  }
}

provider "aws" {
  alias   = "redshift_account"
  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      eEvironment = var.environment
      Purpose     = "Redshift Spectrum Demo"
    }
  }
}


# As of now "brainly/redshift" does not support profile to be defined in provider configuration,
# hence when assume role is used for cross account access to redshift it needs environment to be configured properly
# When Demo code is deployed with s imple AWS CLI configuration via credentials file provider will require either
# AWS_PROFILE variable configured (e.g. AWS_PROFILE=<name> terraform ...) or "default" profile configured with credentials
# from the account where assumed role is created
provider "redshift" {
  alias    = "redshift_account"
  host     = replace(data.aws_redshift_cluster.generic-data-warehouse.endpoint, ":.*", "")
  username = data.aws_redshift_cluster.generic-data-warehouse.master_username
  database = data.aws_redshift_cluster.generic-data-warehouse.database_name
  temporary_credentials {
    cluster_identifier = data.aws_redshift_cluster.generic-data-warehouse.cluster_identifier
    region             = var.region
    assume_role {
      arn          = data.aws_iam_role.redshift_deployment_role.arn
      session_name = "redshift-schema-deployment"
    }
  }
}

terraform {
  required_providers {
    redshift = {
      source = "brainly/redshift"
    }
  }
}
