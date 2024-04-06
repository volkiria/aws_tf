# Redshift Spectrum with data publishers in other accounts

## Cross-account placement of resources

The Redshift Spectrum is a feature that may represent files that contain table-structured data as tables in Redshift without importing them. 
It utilizes Glue Data Catalog to get the location, schema, and runtime metrics of the data files, and then communicates directly with the actual data source (e.g. reads file from particular S3 bucket)

This implementation has following limitations:
- Below resources are located in the same aws account (though may be placed in different accounts as well):
  - S3 bucket with the data files to be represented as tables
  - Glue Data Catalog and crawlers
  - Redshift cluster
- Publisher service of the data to be represented as table is located in different AWS account, while only having access to publish its artifacts to particular S3 bucket(s)

Implementation should be easily scaled to add more file-based tables that may be published with different services (potentially from different accounts)

Code is implemented in 2 separated pieces:
- code that defines resources in the AWS account where publisher service reside (IAM policies and roles)
- code that defines resources in the AWS account where data are represented in Redshift (Glue, S3, IAM policies and roles, Redshift cluster and resources in the cluster)