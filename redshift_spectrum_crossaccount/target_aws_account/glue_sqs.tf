data "aws_iam_policy_document" "external_tables_crawler_bucket_notifications" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.external_tables_bucket_notifications.arn]
    }
  }
}

resource "aws_sqs_queue" "external_tables_crawler_bucket_notifications" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)
  name     = local.external_tables_crawler_names[each.value]
  policy   = data.aws_iam_policy_document.external_tables_crawler_bucket_notifications[each.value].json

  tags = {
    Name = local.external_tables_crawler_names[each.value]
  }
}

resource "aws_sns_topic_subscription" "external_tables_crawler_bucket_notifications" {
  provider = aws.glue_account

  for_each            = toset(var.tables_categories)
  topic_arn           = aws_sns_topic.external_tables_bucket_notifications.arn
  protocol            = "sqs"
  endpoint            = aws_sqs_queue.external_tables_crawler_bucket_notifications[each.value].arn
  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode({
    "Records" : {
      "s3" : {
        "object" : {
          "key" : [
            { "prefix" : "${each.value}/" }
          ]
        }
      }
    }
  })
}
