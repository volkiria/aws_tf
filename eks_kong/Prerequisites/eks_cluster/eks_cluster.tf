resource "aws_eks_cluster" "demo" {
  name     = "${var.environment}-${var.org_code}-demo-cluster"
  role_arn = aws_iam_role.demo_eks_cluster_access.arn
  version  = 1.29

  vpc_config {
    subnet_ids = [aws_subnet.demo_eks_private_b.id, aws_subnet.demo_eks_private_c.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo_eks_cluster_access,
  ]
}



resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "${var.environment}-${var.org_code}-demo-workers"
  node_role_arn   = aws_iam_role.demo_eks_cluster_node_access.arn
  subnet_ids = [
    aws_subnet.demo_eks_private_b.id,
    aws_subnet.demo_eks_private_c.id
  ]

  instance_types = [
    "t3.medium",
    "t3.large"
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo_eks_cluster_access,
    aws_iam_role_policy_attachment.demo_eks_nodegroup_access_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo_eks_kong_nodegroup_access_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.demo_eks_kong_nodegroup_access_AmazonEKS_CNI_Policy
  ]
}

##### OIDC provider for EKS Cluster

data "tls_certificate" "demo" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "demo" {
  url             = data.tls_certificate.demo.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.demo.certificates[0].sha1_fingerprint]
}

