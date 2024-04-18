# This role will be attached to Redshift cluster
# The policy that allows assume any role in list of target accounts will be created
# there will not be limitations for the list of roles in those accounts
# The roles in target accounts will restrict principal that may assume it
locals {
  external_tables_redshif_allowed_roles_toassume = [for account in concat(var.external_table_source_accounts, [data.aws_caller_identity.current.account_id]) : "arn:aws:iam::${account}:role/${var.environment}-${var.org_code}-exttables-*"]
}

resource "aws_iam_role" "external_tables_redshift_allow_assume" {
  provider = aws.redshift_account

  name               = "${var.environment}-${var.org_code}-exttables-redshift-cluster"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "external_tables_redshift_allow_assume" {
  provider = aws.redshift_account

  statement {
    sid = "AssumeRolesInExternalTablesSourceAccounts"

    actions = [
      "s3:AssumeRole",
    ]

    resources = local.external_tables_redshif_allowed_roles_toassume
  }
}


resource "aws_iam_policy" "external_tables_redshift_allow_assume" {
  provider = aws.redshift_account

  name   = "${var.environment}-${var.org_code}-exttables-redshift-cluster-allow-assume"
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_redshift_allow_assume.json
}

resource "aws_iam_role_policy_attachment" "external_tables_redshift_allow_assume" {
  provider = aws.redshift_account

  role       = aws_iam_role.external_tables_redshift_allow_assume.name
  policy_arn = aws_iam_policy.external_tables_redshift_allow_assume.arn
}

# Deployment role to be used with "brainly/redshift" provider
# These permissions may be added to regular deployment role used by CI/CD tool
# With this demo code access keys are used for deployment and role only created for respective user to assume
# to demonstrate preferred way to configure provider (without password in the code
# At least redshift:DescribeClusters and redshift:GetClusterCredentials permissions is needed to generate temporary credentials
# Another simplifications is that the Redshift user for which credentials may be generated is not restricted (any user allowed)
resource "aws_iam_role" "deployment_role_redshift" {
  provider = aws.redshift_account

  name               = "${var.environment}-${var.org_code}-redshift-deploy-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_caller_identity.current.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "deployment_role_redshift" {
  provider = aws.redshift_account

  statement {
    sid = "DescribeRedshiftClusters"

    actions = [
      "redshift:DescribeClusters"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowGenerateTempRedshiftCreds"

    actions = [
      "redshift:GetClusterCredentials"
    ]
    resources = [
      "arn:aws:redshift:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_redshift_cluster.generic-data-warehouse.cluster_identifier}/${aws_redshift_cluster.generic-data-warehouse.master_username}",
      "arn:aws:redshift:${var.region}:${data.aws_caller_identity.current.account_id}:dbname:${aws_redshift_cluster.generic-data-warehouse.cluster_identifier}/${aws_redshift_cluster.generic-data-warehouse.database_name}"
    ]
  }
}

resource "aws_iam_policy" "deployment_role_redshift" {
  provider = aws.redshift_account

  name   = "${var.environment}-${var.org_code}-redshift-deploy-role"
  path   = "/"
  policy = data.aws_iam_policy_document.deployment_role_redshift.json
}

resource "aws_iam_role_policy_attachment" "deployment_role_redshift" {
  provider = aws.redshift_account

  role       = aws_iam_role.deployment_role_redshift.name
  policy_arn = aws_iam_policy.deployment_role_redshift.arn
}