# Redshift Spectrum with data publishers in other accounts

## Cross-account placement of resources

The Redshift Spectrum is a feature that may represent files that contain table-structured data as tables in Redshift without importing them. 
It utilizes Glue Data Catalog to get the location, schema, and runtime metrics of the data files, and then communicates directly with the actual data source (e.g. reads file from particular S3 bucket)

This implementation has following limitations:
- Resources located in the same aws account:
  - S3 bucket with the data files to be represented as tables
  - Glue Data Catalog and crawlers
- Resources located in different accounts
  - Redshift cluster (it is expected that Data Warehouse is managed separately and exists before Glue and S3 infrastructure are been deployed)
  - Publisher service of the data (to be represented as table) and only represented with the IAM role that may be assumed with EC2 service (in real world scenario actual service or chained role should be configured as principle to assume it)

## Prerequisites

The only prerequisite for this code is Data Warehouse implemented as Redshift Cluster. Redshift Spectrum would be used to visualize table structured file data as table.
Following resources would be created using code from Prerequisites folder:
- Redshift Cluster
- IAM role associated with Redshift Cluster that would be allowed to assume roles from number of accounts configured as list via the inputs
- IAM role used for deployment of the Redshift external schemas (cross account type of configuration)

Following values would be a requirement to the main code:
- the name of the cluster:
  - with this implementation is used to source data about cluster to facilitate demo deployments, but in real scenario some other implementation may be preferred 
- the name of the role attached to Redshift Cluster to assume roles from other accounts that may publish external tables:
  - with this implementation is used to source data about cluster's role to facilitate demo deployments, but in real scenario some other implementation may be preferred
  - used to configure roles that provide access to Glue and S3 resources

## Main code - target_aws_account

### s3.tf
This part of code implements S3 bucket that would be used to publish data files within predefined but configurable folder/object structure within S3 bucket:
- top-level folders are "table category" folders that have their pre-defined name pushed from tables_categories input variable
  - its name corresponds to the name of external schema in Redshift
  - separate crawler is created to process any table under each "table category" folder
  - table files should not be published under root of the bucket or under root of the "table category" folder
- each table file should be published in separate "table" sub-folder under one of supported "table category" folders
  - sub-folder names should be negotiated with data consumers since this would be visible as Table name in Redshift
  - path to supported sub-folder should be communicated to the team that supports respective publishing service
  - sub-folders with predefined names are created by this code; names are configured via inputs variable table_publishers
  - access to each sub-folder is restricted via IAM roles defined as part of this code:
    - one particular publisher service (via IAM role) as configured in input variable table_publishers will be permitted to Put objects (to minimize the risk of publishing several tables under the same sub-folder, causing unexpected table naming in Redshift)
    - crawler that processes "table category" folder will be permitted to Get objects from "table category" and any of its sub-folders
    - Redshift spectrum external schema (via IAM role chaining; on the level of "table category" folder) will be permitted to Get from "table category" and any of its sub-folders

### kms.tf
This code creates KMS key used across the Glue and S3 resources for encryption:
- creates KMS key
- defines key access policy with 3 main levels of access:
  - administrative access (some set of admin users/groups/roles defined in external_tables_key_administrator_access input variable)
  - encrypt and decrypt access (to facilitate Reads of the encrypted contents)
    - access from the same account and access from AWS services (account's root and service principles without conditions)
    - access to principals defined in external_tables_key_encryptdecrypt_access input variable
    - access for any IAM role generated for Glue crawlers and Redshift Spectrum access
  - encrypt only access (to provide Write only access to the S3 bucket, but not Read access, expected to be used by external publishers)
    - access to principals defined in external_tables_key_encryptonly_access input variable
    - [TODO] access for any IAM role generated for external publishers

All variables mentioned above are lists of strings that may have 2 types of principle definitions:
- short definitions is expected to be only a principle from the same account where Glue and S3 resources are hosted:
  - should consist from \<type> (any valid IAM type like role, user, etc.) and \<name> of the IAM object in format "\<type>/\<name>"
  - full ARNs will be generated for the account that is used to deploy this demo
- full ARNs, that are mainly expected to be principals from another accounts
  - these ARNs will be used as is

### glue.tf
For this implementation only very basic Glue infrastructure would be defined, that does not utilize some valuable Glue features (e.g. LakeFormation for fine-grained access control):
- Glue Data Catalog databases that correspond to "table category" folders 
- Crawlers where each processes exactly one "table category" folder
- Security configuration to encrypt all available artifacts that crawler creates

### glue_iam.tf
This code creates a set of IAM roles to be assumed by Glue crawler (and respective policy) to provide required access:
- Read access to "table category" folder and any sub-folders for respective crawler only
- Permissions to configure encryption options and assign KMS key to its own CloudWatch Log group

### glue_sqs.tf [TODO]
This code creates SQS queue used by Glue crawler to only re-crawl modified files, avoiding full "table category"folder re-crawl. 
This approach allows to reduce costs associated with Glue activities. This is not critical with Parquette files or with smaller CSV files representing table data. But it may generate considerable costs if extensive CSV files are published with the external service. This approach will ensure that Crawler will only re-crawl modified objects, avoiding undesired costs from re-crawling of unchanged objects.

### redshift.tf
Prerequisites: It is expected that Redshift cluster's endpoint is available for network connections to port 5439 from the location where terraform code is been applied (e.g. using VPN connection).

This code utilizes brainly/redshift terraform provider to create external schema in existing Redshift Cluster. With this implementation provider is configured using data sources to read:
- Redshift cluster
- IAM role associated with Redshift cluster that allows it to assume other external roles
- deployment role which is IAM role that provides access to generate temporary credentials in Redshift

Data sources mentioned above uses separate provider configuration pointing to the Redshift's account to simplify Demo deployment. 
If this scenario is not acceptable, all required values could be pushed through input variables.

Also, this implementation assumes following:
- Redshift Cluster's master user is used to deploy external schemas into cluster. This is not recommended for the real scenarios, separate user with appropriate privileges should be created and configured as string for brainly/redshift provider. Also, the deployment role configured as part of Prerequisites should allow to generate temporary credentials for this particular user. 
- Database is defined as DB created along with the cluster. This may not be the case for real scenario, hence real target Redshift's DB should be configured for the brainly/redshift provider.

This code communicates with Redshift Cluster's endpoint to create external schemas:
- separate external schema is created for each "table category" folder ("-" are replaced with "_" in table category names due to naming limitations in Redshift)
- each external schema is associated with 2 roles:
  - IAM role from the Redshift's account associated with the cluster (that allows assuming external roles)
  - IAM role in Glue's account that provides access to Glue and S3 for the respective "table category" only (and only can be assumed by the cluster's role above)

### redshift_iam.tf
This code generates IAM roles in Glue's account that provide required permissions to Redshift's external schemas to access respective "table category" resources (n Glue and S3)
These IAM roles are defined so only Redshift Cluster's "allowassume" role could assume them, hence no other principal will be allowed to benefit from these permissions.
Following access is provided:
- Access to read metadata from particular Database and tables of the Glue Data Catalog
- Read access to S3 bucket's particular "table category" top level folder only

### lambda.tf [TODO]
This code will define lambda function that will be triggered by any object Put operations in S3 bucket. It will run respective crawler depending on the top-level folder where object was created/updated.
All relevant data (if any required) from notification message will be pushed to crawler.

This approach is used to overcome latency after new table file version publication and before updated data become available in Redshift for querying.

## Main code - source_aws_account [TODO]
 This code is aimed to create required infrastructure in accounts where publishing services reside
 

## Demo Deployment [TODO]

Here will be described steps to deploy Demo using this code