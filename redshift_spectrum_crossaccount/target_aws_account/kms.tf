locals {
  external_tables_key_administrator_access_list       = [for principal in var.external_tables_key_administrator_access : strcontains(principal, "arn:") ? principal : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${principal}"]
  external_tables_key_encryptonly_access_list         = [for principal in var.external_tables_key_encryptonly_access : strcontains(principal, "arn:") ? principal : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${principal}"]
  external_tables_key_encryptdecrypt_access_list      = [for principal in var.external_tables_key_encryptdecrypt_access : strcontains(principal, "arn:") ? principal : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${principal}"]
  external_tables_crawler_roles_list                  = { for category in var.tables_categories : category => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.external_tables_crawler_role_names[category]}" }
  external_tables_redshift_roles_list                 = { for category in var.tables_categories : category => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.external_tables_redshift_role_names[category]}" }
  external_tables_publisher_roles_list                = { for publisher, properties in var.table_publishers : publisher => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.external_tables_publisher_role_names[publisher]}" }
  external_tables_key_encryptdecrypt_access_list_full = concat(local.external_tables_key_encryptdecrypt_access_list, [for role in local.external_tables_crawler_roles_list : role], [for role in local.external_tables_redshift_roles_list : role])
  external_tables_key_encryptonly_access_list_full    = concat(local.external_tables_key_encryptonly_access_list, [for role in local.external_tables_publisher_roles_list : role])
}

resource "aws_kms_key" "external_tables_key" {
  provider = aws.glue_account

  description             = "KMS key to encrypt external tables in S3 bucket"
  deletion_window_in_days = 10
  key_usage               = "ENCRYPT_DECRYPT"
  policy                  = data.aws_iam_policy_document.external_tables_key_access.json
  is_enabled              = true
}

resource "aws_kms_alias" "external_tables_key" {
  provider = aws.glue_account

  name          = "alias/${var.environment}-${var.org_code}-exttables-key"
  target_key_id = aws_kms_key.external_tables_key.key_id
}

data "aws_iam_policy_document" "external_tables_key_access" {
  provider = aws.glue_account

  statement {
    sid = "Allow key usage from any entity in the owner account"

    actions = [
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:RevokeGrant",
      "kms:ListGrants",
      "kms:CreateGrant"
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    principals { # Allow access from the CloudWatch Logs service
      type = "Service"
      identifiers = [
        "logs.us-east-1.amazonaws.com"
      ]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow administrative access to principles from admin list"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"

      values = local.external_tables_key_administrator_access_list
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow encrypt access to principles from encryptonly list"

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"

      values = local.external_tables_key_encryptonly_access_list_full
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow use of the key (encrypt/decrypt access) to principles from encryptonly and encryptdecrypt lists"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"

      values = local.external_tables_key_encryptdecrypt_access_list_full
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow Grants for the key to AWS resources that generate grant on behalf of principles from encryptdecrypt list"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"

      values = concat(local.external_tables_key_encryptdecrypt_access_list_full, local.external_tables_key_encryptonly_access_list)
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true",
      ]
    }
  }
}

