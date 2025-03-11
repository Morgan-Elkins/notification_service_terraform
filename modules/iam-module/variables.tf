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

variable "priority_queue_1_url" {
  type        = string
  description = "Q1 url"
}

variable "priority_queue_2_url" {
  type        = string
  description = "Q2 url"
}

variable "priority_queue_3_url" {
  type        = string
  description = "Q3 url"
}

variable "dead_letter_queue_url" {
  type        = string
  description = "Deadletter queue url"
}