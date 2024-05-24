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
