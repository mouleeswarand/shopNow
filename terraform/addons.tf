resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.shopnow.name
  addon_name    = "metrics-server"
  addon_version = "v0.9.0-eksbuild.14"

  depends_on = [
    aws_eks_node_group.shopnow
  ]
}

# Register this cluster's OIDC issuer with IAM.
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.shopnow.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "shopnow-dev-eks-oidc"
  }
}

# IAM role used only by the EBS CSI controller service account.
resource "aws_iam_role" "ebs_csi" {
  name = "shopnow-dev-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.shopnow.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.67.2-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_node_group.shopnow,
    aws_iam_role_policy_attachment.ebs_csi
  ]
}