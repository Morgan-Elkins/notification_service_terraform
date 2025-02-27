output "external_dns_policy_arn" {
  value = aws_iam_policy.external_dns_policy.arn
}

output "oidc_provider_var" {
  value = var.oidc_provider
}
output "assume_role_policy" {
  value = data.aws_iam_policy_document.instance_assume_role_policy.json
}
