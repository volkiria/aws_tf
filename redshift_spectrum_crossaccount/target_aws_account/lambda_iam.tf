locals {
  external_tables_crawler_trigger_lambda_role_name = "${var.environment}-${var.org_code}-exttables-crawler-trigger"
  external_tables_crawler_arns                     = [for category in toset(var.tables_categories) : aws_glue_crawler.external_tables[category].arn]
}

data "aws_iam_policy_document" "external_tables_crawler_trigger_lambda_access" {
  provider = aws.glue_account

  statement {
    sid = "StartCrawler"

    actions = [
      "glue:StartCrawler",
    ]

    resources = local.external_tables_crawler_arns
  }

  statement {
    sid = "ListCrawlers"

    actions = [
      "glue:ListCrawlers",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_tables_crawler_trigger_lambda_access" {
  provider = aws.glue_account

  name   = local.external_tables_crawler_trigger_lambda_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.external_tables_crawler_trigger_lambda_access.json

  tags = {
    Name = local.external_tables_crawler_trigger_lambda_role_name
  }
}

resource "aws_iam_role" "external_tables_crawler_trigger_lambda_access" {
  provider = aws.glue_account

  name               = local.external_tables_crawler_trigger_lambda_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = local.external_tables_crawler_trigger_lambda_role_name
  }
}

resource "aws_iam_role_policy_attachment" "external_tables_crawler_trigger_lambda_access" {
  provider = aws.glue_account

  role       = aws_iam_role.external_tables_crawler_trigger_lambda_access.name
  policy_arn = aws_iam_policy.external_tables_crawler_trigger_lambda_access.arn

  depends_on = [
    aws_iam_role.external_tables_crawler_trigger_lambda_access,
    aws_iam_policy.external_tables_crawler_trigger_lambda_access
  ]
}

resource "aws_iam_role_policy_attachment" "external_tables_lambda_trigger_access_awslambdabasicexecutionrole" {
  provider = aws.glue_account

  role       = aws_iam_role.external_tables_crawler_trigger_lambda_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [
    aws_iam_role.external_tables_crawler_trigger_lambda_access
  ]
}