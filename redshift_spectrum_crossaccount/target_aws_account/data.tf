data "aws_caller_identity" "current" {
  provider = aws.glue_account
}

data "aws_redshift_cluster" "generic-data-warehouse" {
  provider           = aws.redshift_account
  cluster_identifier = "${var.environment}-${var.org_code}-cluster"
}

data "aws_iam_role" "redshift_cluster_role_toassume_external_roles" {
  provider = aws.redshift_account
  name     = "${var.environment}-${var.org_code}-exttables-redshift-cluster"
}

data "aws_iam_role" "redshift_deployment_role" {
  provider = aws.redshift_account
  name     = "${var.environment}-${var.org_code}-redshift-deploy-role"
}