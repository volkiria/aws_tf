resource "aws_redshift_cluster" "generic-data-warehouse" {
  provider = aws.redshift_account

  cluster_identifier     = "${var.environment}-${var.org_code}-cluster"
  database_name          = "exttablesdemo"
  master_username        = "admin"
  master_password        = "admin-123-Temporary-Password"
  node_type              = "dc2.large"
  cluster_type           = "single-node"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.generic_data_warehouse_sg.id]

  lifecycle {
    ignore_changes = [
      master_password,
    ]
  }

  tags = {
    Name = "${var.environment}-${var.org_code}-cluster"
  }
}

resource "aws_redshift_cluster_iam_roles" "generic-data-warehouse" {
  provider = aws.redshift_account

  cluster_identifier = aws_redshift_cluster.generic-data-warehouse.id
  iam_role_arns      = [aws_iam_role.external_tables_redshift_allow_assume.arn]
}