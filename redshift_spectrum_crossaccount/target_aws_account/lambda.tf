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
}

resource "aws_lambda_permission" "external_tables_trigger_crawler_s3_notifications" {
  provider = aws.glue_account

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.external_tables_trigger_crawler.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.external_tables.arn
}

resource "aws_s3_bucket_notification" "external_tables_trigger_crawler_s3_notifications" {
  provider = aws.glue_account

  bucket = aws_s3_bucket.external_tables.id
  lambda_function {
    id                  = "${var.environment}-${var.org_code}-exttables-trigger-crawler"
    lambda_function_arn = aws_lambda_function.external_tables_trigger_crawler.arn
    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*",
    ]
  }
  depends_on = [
    aws_lambda_permission.external_tables_trigger_crawler_s3_notifications,
    aws_lambda_function.external_tables_trigger_crawler
  ]
}