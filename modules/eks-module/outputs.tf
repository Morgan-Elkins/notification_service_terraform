output "eks_service_account_arn" {
    description = "The Eks service account arn"
    value = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}

