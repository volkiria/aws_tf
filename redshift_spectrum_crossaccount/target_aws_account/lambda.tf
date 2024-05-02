data "archive_file" "external_tables_trigger_crawler" {
  type        = "zip"
  source_file = "trigger_crawler_lambda/lambda.py"
  output_path = "trigger_crawler_lambda.zip"
}

resource "aws_lambda_function" "external_tables_trigger_crawler" {
  provider = aws.glue_account

  filename      = "trigger_crawler_lambda.zip"
  function_name = "${var.environment}-${var.org_code}-exttables-trigger-crawler"
  role          = aws_iam_role.external_tables_crawler_trigger_lambda_access.arn
  handler       = "lambda.trigger_crawler"

  source_code_hash = data.archive_file.external_tables_trigger_crawler.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      ENVIRONMENT         = var.environment,
      CRAWLER_NAME_PREFIX = local.crawler_name_prefix
    }
  }

  tags = {
    Name = "${var.environment}-${var.org_code}-exttables-trigger-crawler"
  }
}

resource "aws_sns_topic_subscription" "external_tables_trigger_crawler" {
  provider = aws.glue_account

  topic_arn = aws_sns_topic.external_tables_bucket_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.external_tables_trigger_crawler.arn
}

resource "aws_lambda_permission" "external_tables_bucket_notifications" {
  provider = aws.glue_account

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.external_tables_trigger_crawler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.external_tables_bucket_notifications.arn
}