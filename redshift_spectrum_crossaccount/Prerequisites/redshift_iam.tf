# This role will be attached to Redshift cluster
# The policy that allows assume any role in list of target accounts will be created
# there will not be limitations for the list of roles in those accounts
# The roles in target accounts will restrict principal that may assume it
locals {
  external_tables_redshif_allowed_roles_toassume = [for account in concat(var.external_table_source_accounts, [data.aws_caller_identity.current.account_id]) : "arn:aws:iam::${account}:role/external_tables_*"]
}

resource "aws_iam_role" "external_tables_redshift_allow_assume" {
  name               = "${var.environment}-${var.org_code}-redshift-cluster-role"
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
  statement {
    sid = "AssumeRolesInExternalTablesSourceAccounts"

    actions = [
      "s3:AssumeRole",
    ]

    resources = local.external_tables_redshif_allowed_roles_toassume
  }
}


resource "aws_iam_policy" "external_tables_redshift_allow_assume" {
  name   = "${var.environment}-${var.org_code}-redshift-cluster-allow-assume"
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_redshift_allow_assume.json
}

resource "aws_iam_role_policy_attachment" "external_tables_redshift_allow_assume" {
  role       = aws_iam_role.external_tables_redshift_allow_assume.name
  policy_arn = aws_iam_policy.external_tables_redshift_allow_assume.arn
}

