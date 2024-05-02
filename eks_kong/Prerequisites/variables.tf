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

variable "external_table_source_accounts" { # Account ID where cluster is hosted will be appended to this list
  description = "List of accounts from which Redshift may source external schemas (except Redshift's account itself)"
  type        = list(string)
}

variable "generic_data_warehouse_vpc_id" {
  description = "VPC ID where Redshift cluster will be attached"
  type        = string
  default     = "default"
}

variable "generic_data_warehouse_allowed_cidrs" {
  description = "List of CIDRs allowed to access Redshift"
  type        = list(string)
}