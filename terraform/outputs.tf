output "vpc_id" {
  description = "ID of the ShopNow development VPC"
  value       = aws_vpc.shopnow.id
}

output "eks_cluster_name" {
  description = "Name of the ShopNow EKS cluster"
  value       = aws_eks_cluster.shopnow.name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.shopnow.endpoint
}

output "eks_node_group_name" {
  description = "Name of the EKS managed node group"
  value       = aws_eks_node_group.shopnow.node_group_name
}