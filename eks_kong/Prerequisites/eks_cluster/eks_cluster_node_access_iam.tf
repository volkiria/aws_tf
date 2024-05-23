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

# This policy is mandatory and may not be avoided
resource "aws_iam_role_policy_attachment" "demo_eks_nodegroup_access_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo_eks_cluster_node_access.name
}

# This policy is better to be removed, while providing respective access (attach the same policy) via IAM role attached to the aws-node service account under kube-system namespace
#resource "aws_iam_role_policy_attachment" "eks_kong_nodegroup_access_AmazonEKS_CNI_Policy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#  role       = aws_iam_role.demo_eks_cluster_node_access.name
#}


# This policy has excessive permissions that allow access to any image in ECR for the same account
resource "aws_iam_role_policy_attachment" "eks_kong_nodegroup_access_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo_eks_cluster_node_access.name
}

