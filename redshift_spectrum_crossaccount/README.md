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

### lambda.tf
This code deploys Lambda using python code from "trigger_crawler_lambda" folder. This lambda is triggered by any object create or delete events in external tables S3 bucket. It analyzes object's key (particularly its path) to trigger respective crawler for re-crawl.
Following resources are created:
- Lambda function
- lambda permission (to be used by S3 service to invoke lambda that will process event notification)
- S3 notification for the external tables bucket

### trigger_crawler_lambda/lambda.py
This is a simple Python code that:
- Analyzes incoming S3 notification event to determine if any of supported crawlers should be started 
- Starts relevant crawler if event is concerned with the object in respective folder
- Skips event if there is no changes in the data to be represented (e.g. if there is only folder was created)

### lambda_iam.tf
This code creates IAM role for Lambda to obtain required permissions upon execution:
- Allows to list crawlers
- Allows to start only crawlers created by this same code


## Main code - source_aws_account [WILL NOT BE IMPLEMENTED]

It was planned initially to define in this part of code any infrastructure in accounts where publishing services reside. As if Demo it was supposed to be IAM roles to be assumed by EC2 service so EC2 instance could be used to emulate actions of publishing service

It was decided at later point that IAM roles for such test may be created manually and added then toi the list of publishers in the main code
 

## Demo Deployment

### Deployment of prerequisites

#### Configure input variables
Prerequisites/inputs.tfvars file has some values assigned to each required input variable that will allow to deploy demo resources.
There are some "dummy" values used as external AWS account IDs and ARNs that do not correspond to actual resources. This will not lead to deployment failure since all of them are used in the way that will not trigger verification of particular resource existence.
Following input values may be configured:
- **environment** - is used in the naming convention for the resources generated; may be modified, but should be kept aligned with the main code's input values (or data.tf in the main code should be modified to search for actual resources created as part of Prerequisites)
- **org_code** - is used in the naming convention for the resources generated; may be modified, but should be kept aligned with the main code's input values (or data.tf in the main code should be modified to search for actual resources created as part of Prerequisites)
- **region** - the region where resources will be created (if region for Prerequisite and main code will differ, then respective provider configurations in the main code should be configured appropriately; initially it is expected that all Demo resources are created in the same region)
- **external_table_source_accounts** - if configured with an empty list [] value, the Demo is expected not to use possibility to separate Redshift and Glue+S3 infrastructure in different account. In any case at least account where Redshift cluster is created will be considered as potential source of external tables. 
- **generic_data_warehouse_allowed_cidrs** - for simplification of the Demo deployment Redshift cluster created with this code is publicly accessible, but security group shoul be configured to allow access to 5439 port for any required for required IPs. At least IP address for the desktop used to deploy main code the demo need to be allowed (make sure to define IP in CIDR format)

#### Deploy prerequisites

Switch to the Prerequisites and execute terraform apply command while using input.tfvars.
Following will be done:
- Redshift cluster created with public access (for simplification)
- Security Group will be created and assigned to Redshift cluster. If required SIDR was not configured as part of inputs, respective rule may be added manually
- IAM role will be created and assigned to Redshift cluster allowing to assume all roles in "table-source" accounts with expected prefix, so cluster could obtain necessary Glue and S3 permissions to represent tables from supported table categories
- IAM role will be created as "deployment role" In this code it only allows to generate temporary credentials for Redshift's master user for default database created as part of Redshift cluster. Following should be considered for real scenarios:
  - If there is deployment role is assumed as part of CI/CD pipeline, this permissions may be added there while not creating a separate role
  - It is not recommended to use master user for such operations, rather separate user with respective permissions should be created and used in deployment role

### Deployment of the main code in target account

With this Demo by "target account" it is considered account that is a target for external services to publish their "table-formatted" artifacts that should be represented in Redshift aas tables.
Following categories of resources  will be created:
- **Glue resources** that implements a set of databases and crawlers based on configuration from input.tfvars. Separate database and crawler is created to support each "table category"
- **KMS key** that is used to encrypt any associated data - S3 objects, logs, glue metadata, etc.
- **S3 bucket with folders** for each configured "table category" and "dummy" sub-folder representing dummy table (to ensure correct naming of the tables published at later point to the category folder)
- **Lambda** that is listening for create ad delete events in the bucket and initiates re-crawl in case of need
- [TODO] **SQS queues** to limit thr crawling vector to only modified files (to avoid re-crawling files that were not changed)
- Set of IAM roles that may be assumed by only expected external principals:
  - IAM roles to be assumed by **Glue crawlers** to scan S3 objects under relevant table category folder
  - IAM roles to be assumed by **Redshift's external schemas** to read data from Glue database and respective S3 objects for relevant table category only
  - IAM roles for the **external publishers** to write "table-formatted" artifacts under only expected folders in S3 bucket (as per configuration in the inputs.tfvars)
  - IAM role for the **Lambda function** allowing it to start only supported Glue crawlers

#### Configure input variables
- **environment** - is used in the naming convention for the resources generated; may be modified, but should be kept aligned with the main code's input values (or data.tf should be modified to search for actual resources created as part of Prerequisites)
- **org_code** - is used in the naming convention for the resources generated; may be modified, but should be kept aligned with the main code's input values (or data.tf should be modified to search for actual resources created as part of Prerequisites)
- **region** - the region where resources will be created (if region for Prerequisite and main code will differ, then respective provider configurations in this part of code should be configured appropriately; initially it is expected that all Demo resources are created in the same region)
- **tables_categories** - list of strings that defined supported table categories. If is expected that names would be 1-2 words interconnected with '-' character. These values will be used to generate AWS resource names and folders within S3 bucket, as well as patterns in policies. Example configuration is present in input.tfvars file
- **table_publishers_roles** - list of supported external publishers with their associates IAM roles (could be the roles from external accounts) that will be allowed to assume publisher respective roles in this account (with all required permissions based on configuration in inputs.tfvars)
- **table_publishers** - map of lists, where key represents the name of the service (aligned with the names in "table_publishers_roles") and value represents the list of objects that each define separate "table" that service will publish (each such object may define name of the table and table category that it will be assigned)
- lists of principles to provide different level of access to KMS key: 
  - **external_tables_key_administrator_access** - to provide administrative access; should never be empty (in real scenario if code is deployed using CI/CD pipeline it could be considered to add it as administrative principal)
  - **external_tables_key_encryptonly_access** - to provide encrypt only access to the Key; any external publisher IAM role created with this code will be added to this access category (so they would not be able to read objects from S3 bucket even of by error access would be added to the role); this list is an option to include additional principals
  - **external_tables_key_encryptdecrypt_access** - to provide encrypt and decrypt access to the Key; any Glue and Redshift IAM role created with this code will be added to this access category; this list is an option to provide additional principals

#### Configure providers
There are 3 providers defined in this part of Demo code:
- hashicorp/aws provider with **"redshift_account"** alias - to access AWS account where Redshift cluster is deployed
  - Here is configured to use pre-defined CLI profile on the desktop, though any valid configuration could be defined to access respective account
  - Make sure that region is aligned with what was configured while deploying Prerequisites
- hashicorp/aws provider with **"glue_account"** alias - to access AWS account where Glue and S3 resources are created (the main goal of this part of code)
  - Here is configured to use pre-defined CLI profile on the desktop, though any valid configuration could be defined to access respective account
- brainly/redshift provider with alias **"redshift_account"** alias - to access Redshift cluster using Deployment role created as part of Prerequisites. 
  - Due to limitations (as of time of code creation) of this provider profile/role that will be used to assume then role from temporary_credentials section may not be defined, hence either default CLI provide should be defined or AWS_PROFILE variable pushed when terraform command executed, this profile should be allowed to assume deployment role from Redshift's account. With this implementation to simplify demo deployment mentioned role is configured to be assumable by the principal used to Deploy Prerequisites; hence the same profile should be used here.  
  - To simplify Demo deployment major part of parameters for this provider are read from data sources (read from Redshift's account). This approach may be unacceptable in real scenario, in this case respective values should be configured manually of via additional input variables
  - Make sure that region configured in temporary_credentials section is aligned with the region used to deploy Prerequisites (the region where deployment role exists)
  - Make sure that IP address or range from where deployment will be performed was allowed to access Redshift cluster on port 5439 (check clusters security group inbound rules)

### Deploy main code in target account

Switch to the target_aws_account folder and execute terraform plan/apply commands while using input.tfvars.

## Test Demo deployment

To test deployed infrastructure:
- prepare several CSV files 
- place them in separate folders with some expected names (table names defined for the publishing services in the main code may be used) and place there
- upload these folders under created top level folders (table categories) in the external tables S3 bucket
- observe that respective Glue crawler was triggered and expected tables (including dummy table) were created for each table category (in respective Glue database)
- Use Redshift's Query Editor (old implementation or v2) to connect to Redshift cluster using master user
- Open Demo database (in code "exttablesdemo") and observe available tables under each external schema (table category) configured in inputs.tfvars in main code
  - "dummy" tables should not appear in Redshift
- Query each table to check if contents corresponds to the contents of CSV file