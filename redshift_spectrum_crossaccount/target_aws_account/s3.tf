# Add bucket policy with explicit deny to put objects under root folder or under top-level folders (table categories)
# There will be additional limitations in IAM roles that publish their artifacts to be represented in Redshift.
# Those will be generated based on information in table_publishers input variable, restricting principal to write to only allowed folder

resource "aws_s3_bucket" "external_tables" {
  provider = aws.glue_account

  bucket = "${var.org_code}-${var.environment}-exttables"

  tags = {
    Name        = "${var.org_code}-${var.environment}-exttables"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "external_tables" {
  provider = aws.glue_account

  bucket = aws_s3_bucket.external_tables.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "external_tables" {
  provider = aws.glue_account

  bucket = aws_s3_bucket.external_tables.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "external_tables" {
  provider = aws.glue_account

  bucket = aws_s3_bucket.external_tables.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.external_tables_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_object" "external_tables_categories" {
  provider = aws.glue_account

  for_each = toset(var.tables_categories)

  bucket  = aws_s3_bucket.external_tables.id
  key     = "${each.key}/dummy/dummy.csv"
  content = <<EOF
dummy;table
0;0
EOF
}
