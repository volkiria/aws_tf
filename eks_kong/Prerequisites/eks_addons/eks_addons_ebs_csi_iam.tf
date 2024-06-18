# Role for the EBS CSI driver for EKS Cluster
resource "aws_iam_role" "demo_eks_ebs_csi_access" {
  name               = "${var.environment}-${var.org_code}-demo-cluster-ebs-csi-access"
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
          "${replace(data.aws_iam_openid_connect_provider.demo.url, "https://", "")}:aud": "sts.amazonaws.com",
          "${replace(data.aws_iam_openid_connect_provider.demo.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-cluster-ebs-csi-access"
  }
}


resource "aws_iam_role_policy_attachment" "demo_eks_kong_nodegroup_access_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.demo_eks_ebs_csi_access.name
}