variable "oidc_provider" {
  description = "eks oidc provider name"
  type = string
  default = ""
}

variable "aws_namespace" {
  description = "Name space for aws eks"
  type = string
  default = "morgan"
}