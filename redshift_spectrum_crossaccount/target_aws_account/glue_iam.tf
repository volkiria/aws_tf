locals {
  external_tables_crawler_role_names = { for category in var.tables_categories : category => "${local.external_tables_crawler_names[category]}-crawler-access" }
}

data "aws_iam_policy_document" "external_tables_crawler_access" {
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
        each.value
      ]
    }
  }

  statement {
    sid = "ReadObjectsUnderTableCategoryFolder"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.external_tables.arn}/${each.value}",
      "${aws_s3_bucket.external_tables.arn}/${each.value}/*",
    ]
  }

  statement {
    sid = "EncryptLogGroup"
    actions = [
      "logs:AssociateKmsKey",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups"
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_policy" "external_tables_crawler_access" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  name   = local.external_tables_crawler_role_names[each.value]
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_crawler_access[each.value].json
}

resource "aws_iam_role" "external_tables_crawler_access" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  name               = local.external_tables_crawler_role_names[each.value]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "external_tables_crawler_access_custom" {
  provider = aws.glue_account

  for_each   = toset(var.tables_categories)
  role       = aws_iam_role.external_tables_crawler_access[each.value].name
  policy_arn = aws_iam_policy.external_tables_crawler_access[each.value].arn
}

resource "aws_iam_role_policy_attachment" "external_tables_crawler_access_awsglueservicerole" {
  provider = aws.glue_account

  for_each   = toset(var.tables_categories)
  role       = aws_iam_role.external_tables_crawler_access[each.value].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
