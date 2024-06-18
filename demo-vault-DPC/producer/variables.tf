variable "aws_account_id" {
  type = string
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "tfc_organization" {
  type = string
}

variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "tfc_project_id" {
  type        = string
  description = "tfc project id"
  default = "prj-6TQPUR7PQrtCmfV1"
}