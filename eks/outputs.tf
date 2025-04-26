output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint

}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster."
  value       = module.eks.cluster_security_group_id

}

output "region" {
  description = "The AWS region where the EKS cluster is deployed."
  value       = var.region

}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name

}
