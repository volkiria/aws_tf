resource "redshift_schema" "external_tables_redshift_schema" {
  provider = redshift.redshift_account

  for_each = toset(var.tables_categories)

  name  = replace(each.value, "-", "_")
  owner = "admin"
  external_schema {
    database_name = local.external_tables_crawler_names[each.value] # Required. Name of the db in glue catalog
    data_catalog_source {
      region = var.region
      iam_role_arns = [
        data.aws_iam_role.redshift_cluster_role_toassume_external_roles.arn,
        aws_iam_role.external_tables_redshift_access[each.value].arn,
      ]
    }
  }
}