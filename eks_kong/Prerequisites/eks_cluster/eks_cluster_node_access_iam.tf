# EKS Node Group

resource "aws_iam_role" "demo_eks_cluster_node_access" {
  name               = "demo-node-group"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "demo_eks_nodegroup_access_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo_eks_cluster_node_access.name
}

# It is recommended this policy to be attached to separate IAM role assigned to aws-node Kubernetes ServiceAccount.
# Such implementation is possible but would be more complex. As this code is used only to deploy cluster for
# Kong Demo purposes, I tend to keep it as simple as possible
resource "aws_iam_role_policy_attachment" "eks_kong_nodegroup_access_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo_eks_cluster_node_access.name
}

resource "aws_iam_role_policy_attachment" "eks_kong_nodegroup_access_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo_eks_cluster_node_access.name
}

