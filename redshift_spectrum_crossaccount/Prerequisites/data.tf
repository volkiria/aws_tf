data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  count   = var.generic_data_warehouse_vpc_id == "default" ? 1 : 0
  default = true
}
