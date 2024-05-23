##### VPC CNI plugin
import {
  to = kubernetes_service_account.aws_node
  id = "kube-system/aws-node"
}

resource "kubernetes_service_account" "aws_node" {
  metadata {
    name      = "aws-node"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.demo_eks_vpc_cni_access.arn
    }
  }
}

resource "aws_eks_addon" "demo_vpc_cni" {
  cluster_name = data.aws_eks_cluster.demo.name
  addon_name   = "vpc-cni"
}