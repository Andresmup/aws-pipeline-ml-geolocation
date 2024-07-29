variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "geolocation"
}

variable "app_environment" {
  type        = string
  description = "Application Environment"
  default     = "dev"
}

variable "stage_name" {
  type        = string
  description = "Stage name"
  default     = "apiv1"
}

variable "endpoint_name" {
  type        = string
  description = "Endpoint name"
  default     = "devices"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda handler for python code <python_filename>.<function_name>"
  default     = "lambda_function.lambda_handler"
}

variable "python_runtime" {
  type        = string
  description = "Python lambda runtime"
  default     = "python3.12"
}

variable "parquet_compression_format" {
  type        = string
  description = "Format used in parquet compression"
  default     = "SNAPPY"
}

variable "github_org" {
  type        = string
  description = "Github organization"
  sensitive   = true

}

variable "repository_name" {
  type        = string
  description = "Repository name"
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "Account id"
  sensitive   = true
}
