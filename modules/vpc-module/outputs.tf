output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc_source.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc_source.private_subnets
}

output "intra_subnet_ids" {
  description = "Intra subnet IDs"
  value       = module.vpc_source.intra_subnets
}

output "vpc_id" {
  description = "VPC id"
  value       = module.vpc_source.vpc_id
}

output "cluster_name" {
  description = "Eks cluster name"
  value = local.cluster_name
}

output "vpc_obj" {
  description = "vpc object"
  value = module.vpc_source
}