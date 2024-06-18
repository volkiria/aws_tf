resource "helm_release" "kong_control_plane" {
  name       = "kong-control-plane"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = "2.38.0"
  namespace  = kubernetes_namespace.eks_kong.id

  values = [
    "${file("values-kong-control-plane.yaml")}"
  ]

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
}