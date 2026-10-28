resource "aws_eks_access_entry" "lab_admin" {
  cluster_name  = aws_eks_cluster.shopnow.name
  principal_arn = "arn:aws:iam::625228299204:user/lab-admin"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "lab_admin" {
  cluster_name  = aws_eks_cluster.shopnow.name
  principal_arn = aws_eks_access_entry.lab_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}