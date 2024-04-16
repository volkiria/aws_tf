locals {
  external_tables_crawler_names = { for category in var.tables_categories : category => "${var.environment}-exttables-${category}" }
}

resource "aws_glue_catalog_database" "external_tables" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  name = local.external_tables_crawler_names[each.value]
}

resource "aws_glue_crawler" "external_tables" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  database_name          = aws_glue_catalog_database.external_tables[each.value].name
  name                   = "${var.environment}-exttables-${each.value}"
  role                   = aws_iam_role.external_tables_crawler_access[each.value].arn
  security_configuration = aws_glue_security_configuration.external_tables.name

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.external_tables.bucket}/${each.value}/"
  }
}

# Security configuration do enable encryption of Glue metadata and logs
resource "aws_glue_security_configuration" "external_tables" {
  provider = aws.glue_account

  name = "${var.environment}-exttables"

  encryption_configuration {
    cloudwatch_encryption {
      kms_key_arn                = aws_kms_key.external_tables_key.arn
      cloudwatch_encryption_mode = "SSE-KMS"
    }

    job_bookmarks_encryption {
      kms_key_arn                   = aws_kms_key.external_tables_key.arn
      job_bookmarks_encryption_mode = "CSE-KMS"
    }

    s3_encryption {
      kms_key_arn        = aws_kms_key.external_tables_key.arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}
