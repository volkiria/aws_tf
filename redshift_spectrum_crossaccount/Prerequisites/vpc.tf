locals {
  generic_data_warehouse_vpc_id = var.generic_data_warehouse_vpc_id == "default" ? data.aws_vpc.default[0].id : var.generic_data_warehouse_vpc_id
}

resource "aws_security_group" "generic_data_warehouse_sg" {
  name        = "${var.environment}-${var.org_code}-cluster-sg"
  description = "Allow connections to Generic Data Warehouse"
  vpc_id      = local.generic_data_warehouse_vpc_id

  tags = {
    Name = "${var.environment}-${var.org_code}-cluster-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "generic_data_warehouse_dbaccess" {
  for_each = toset(var.generic_data_warehouse_allowed_cidrs)

  security_group_id = aws_security_group.generic_data_warehouse_sg.id
  cidr_ipv4         = each.value
  from_port         = 5439
  ip_protocol       = "tcp"
  to_port           = 5439
}