variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "erp-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "system_node_instance_type" {
  description = "x86-64 EC2 instance type allowed by the AWS account for the EKS system node group"
  type        = string
  default     = "t3.small"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "erpadmin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
