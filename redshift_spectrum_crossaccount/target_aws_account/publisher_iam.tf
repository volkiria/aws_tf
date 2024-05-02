locals {
  external_tables_publisher_role_names = {
    for publisher, properties in var.table_publishers :
    publisher => "${var.environment}-${var.org_code}-exttables-${replace(publisher, "_", "-")}-publisher"
  }
  external_tables_publisher_table_paths = {
    for publisher, properties in var.table_publishers :
    publisher => [for table in toset(properties) : "${aws_s3_bucket.external_tables.arn}/${table.category}/${table.table_name}/*"]
  }
}

data "aws_iam_policy_document" "external_tables_publisher_access" {
  provider = aws.glue_account

  for_each = var.table_publishers

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
    sid = "PutObjectsUnderTableFolder"
    actions = [
      "s3:PutObject",
    ]

    resources = local.external_tables_publisher_table_paths[each.key]
  }
}

resource "aws_iam_policy" "external_tables_publisher_access" {
  provider = aws.glue_account

  for_each = var.table_publishers

  name   = local.external_tables_publisher_role_names[each.key]
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_publisher_access[each.key].json

  tags = {
    Name = local.external_tables_publisher_role_names[each.key]
  }
}

resource "aws_iam_role" "external_tables_publisher_access" {
  provider = aws.glue_account

  for_each = var.table_publishers

  name               = local.external_tables_publisher_role_names[each.key]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Condition": {
        "ArnEquals": {
          "aws:PrincipalArn": "${var.table_publishers_roles[each.key]}"
        }
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = local.external_tables_publisher_role_names[each.key]
  }
}

resource "aws_iam_role_policy_attachment" "external_tables_publisher_access" {
  provider = aws.glue_account

  for_each   = var.table_publishers
  role       = aws_iam_role.external_tables_publisher_access[each.key].name
  policy_arn = aws_iam_policy.external_tables_publisher_access[each.key].arn
}
