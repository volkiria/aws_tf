# Role for the EKS Cluster

data "aws_iam_policy_document" "demo_eks_cluster_access" {
  statement {
    sid = "CreateEC2Tags"
    actions = [
      "ec2:CreateTags",
    ]

    resources = [
      "arn:aws:ec2:*:*:instance/*",
    ]

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"

      values = [
        "kubernetes.io/cluster/*"
      ]
    }
  }

  statement {
    sid = "Describe"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "demo_eks_cluster_access" {
  name   = "${var.environment}-${var.org_code}-demo-cluster-access"
  path   = "/"
  policy = data.aws_iam_policy_document.demo_eks_cluster_access.json

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-cluster-access"
  }

  depends_on = [
    data.aws_iam_policy_document.demo_eks_cluster_access
  ]
}

resource "aws_iam_role" "demo_eks_cluster_access" {
  name               = "${var.environment}-${var.org_code}-demo-cluster-access"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "${var.environment}-${var.org_code}-demo-cluster-access"
  }

}

resource "aws_iam_role_policy_attachment" "demo_eks_cluster_access" {
  role       = aws_iam_role.demo_eks_cluster_access.name
  policy_arn = aws_iam_policy.demo_eks_cluster_access.arn
}
