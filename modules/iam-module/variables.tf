variable "oidc_provider" {
  description = "eks oidc provider name"
  type        = string
  default     = ""
}

variable "aws_namespace" {
  description = "Name space for aws eks"
  type        = string
  default     = "morgan"
}

variable "cluster_name" {
  description = "Cluster name"
  type = string
}