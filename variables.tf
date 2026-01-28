# Account ID for IAM role ARNs (for cross-account or reuse)
variable "account_id" {
  type        = string
  description = "AWS Account ID for IAM role ARNs."
  default     = ""
}

# SSM Automation role name (for PassRole)
variable "ssm_automation_role_name" {
  type        = string
  description = "Name of the SSM Automation role for PassRole."
  default     = ""
}
variable "region"       { default = "eu-central-1" }
variable "prefix"       { default = "tf-demo-draining" } 
variable "service_name" { default = "fake-app" }
variable "vpc_id"       { default = "vpc-0f7a86b4e16b126a3" }
variable "subnet_ids"   { 
  type    = list(string)
  default = ["subnet-0b746d67b636c3e9d", "subnet-0b6ed127b605b61d5"] 
}

variable "allowed_asgs" {
  type    = string
  default = ""
  description = "Comma-separated list of allowed ASG names. Leave empty to use only prefix."
}
