data "aws_caller_identity" "current" {
  provider = aws.redshift_account
}

data "aws_vpc" "default" {
  provider = aws.redshift_account

  count   = var.generic_data_warehouse_vpc_id == "default" ? 1 : 0
  default = true
}
