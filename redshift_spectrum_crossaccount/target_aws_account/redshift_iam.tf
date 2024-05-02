locals {
  external_tables_redshift_role_names = { for category in var.tables_categories : category => "${var.environment}-${var.org_code}-exttables-${category}-redshift" }
}

data "aws_iam_policy_document" "external_tables_redshift_access" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  statement {
    sid = "ListBuckets"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    sid = "ListObjectsUnderTableCategoryFolder"
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.external_tables.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${each.value}/*"
      ]
    }
  }

  statement {
    sid = "ReadObjectsUnderTableCategoryFolder"
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.external_tables.arn}/${each.value}",
      "${aws_s3_bucket.external_tables.arn}/${each.value}/*",
    ]
  }

  statement {
    sid = "ReadGlueDataCatalogDB"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetDatabases",
      "glue:GetTables",
      "glue:GetPartitions", # subfolders under the "table" folder are considered by Glue crawler as partitions
    ]

    resources = [
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
      aws_glue_catalog_database.external_tables[each.value].arn,
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.external_tables[each.value].name}/*"
    ]
  }

  statement {
    sid = "ExcludeDummyTable"
    actions = [
      "glue:GetTables",
    ]
    effect = "Deny"
    resources = [
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.external_tables[each.value].name}/dummy",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.external_tables[each.value].name}/${each.value}"
    ]
  }
}

resource "aws_iam_policy" "external_tables_redshift_access" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  name   = local.external_tables_redshift_role_names[each.value]
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_redshift_access[each.value].json

  tags = {
    Name = local.external_tables_redshift_role_names[each.value]
  }
}


resource "aws_iam_role" "external_tables_redshift_access" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  name               = local.external_tables_redshift_role_names[each.value]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_iam_role.redshift_cluster_role_toassume_external_roles.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = local.external_tables_redshift_role_names[each.value]
  }
}

resource "aws_iam_role_policy_attachment" "external_tables_redshift_access" {
  provider = aws.glue_account

  for_each   = toset(var.tables_categories)
  role       = aws_iam_role.external_tables_redshift_access[each.value].name
  policy_arn = aws_iam_policy.external_tables_redshift_access[each.value].arn

  depends_on = [
    aws_iam_role.external_tables_redshift_access,
    aws_iam_policy.external_tables_redshift_access
  ]
}
