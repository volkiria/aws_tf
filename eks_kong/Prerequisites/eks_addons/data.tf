data "aws_eks_cluster" "demo" {
  name = "${var.environment}-${var.org_code}-demo-cluster"
}

data "tls_certificate" "demo" {
  url = data.aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

data "aws_iam_openid_connect_provider" "demo" {
  url = data.tls_certificate.demo.url
}