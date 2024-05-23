# Role for the VPC CNI plugin for EKS Cluster
resource "aws_iam_role" "demo_eks_vpc_cni_access" {
  name               = "${var.environment}-${var.org_code}-demo-cluster-vpc-cni-access"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${data.aws_iam_openid_connect_provider.demo.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.aws_iam_openid_connect_provider.demo.url}:aud": "sts.amazonaws.com",
          "${data.aws_iam_openid_connect_provider.demo.url}:sub": "system:serviceaccount:kube-system:aws-node"
        }
      }
    }
  ]
}
EOF

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-cluster-vpc-cni-access"
  }
}

resource "aws_iam_role_policy_attachment" "demo_eks_vpc_cni_access" {
  role       = aws_iam_role.demo_eks_vpc_cni_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
