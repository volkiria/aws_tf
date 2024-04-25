variable "environment" {
  description = "Environment that resources belong to"
  type        = string
}

variable "org_code" {
  description = "Unique code of the organization (for globally unique names)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tables_categories" {
  description = "Supported table categories (correspond to Redshift external schemas names)"
  type        = list(string)
}

variable "table_publishers" {
  description = "Map of the services and tables published by each service with category assigned"
  type = map(list(object({
    table_name = string
    category   = string
  })))
  default = {
    dummy_service = [ # Name of the service that publishes 1 or more tables
      {
        table_name = "dummy_table" # Name of the table to be published (corresponds to the name of sub-folder under the category top-level folder))
        category   = "dummy"       # Category of the table been published (corresponds to the top-level folder in the bucket)
      }
    ]
  }
}
variable "table_publishers_roles" {
  description = "Map of the services and their execution roles (in AWS account when they are hosted)"
  type        = map(string)
  default = {
    dummy_service = "arn:aws:iam::account_id:role/dummy_service"
  }
}

variable "external_tables_key_administrator_access" {
  description = "List of principals granted administrative access to the key used for external tables S3 bucket"
  type        = list(string)
}

variable "external_tables_key_encryptonly_access" {
  description = "List of principals granted encrypt only access to the key used for external tables S3 bucket"
  type        = list(string)
}

variable "external_tables_key_encryptdecrypt_access" {
  description = "List of principals granted encrypt/decrypt access to the key used for external tables S3 bucket"
  type        = list(string)
}
