##### EKS EBS CSI Driver ####
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = data.aws_eks_cluster.demo.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.31.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.demo_eks_ebs_csi_access.arn
}

##### EKS Cert-Manager ####
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.14.5"

  values = [
    "${file("values_eks_addons_cert_manager.yaml")}"
  ]
}

##### EKS LoadBalancer Controller ####

resource "kubernetes_service_account" "demo_eks_lb_controller_service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.demo_eks_lb_controller_access.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "demo_eks_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.demo_eks_lb_controller_service_account,
    helm_release.cert_manager
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.demo.id
  }

  set {
    name  = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }

  set {
    name  = "image.tag"
    value = "v2.8.0"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.demo.name
  }
}