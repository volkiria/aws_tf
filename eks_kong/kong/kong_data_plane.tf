resource "helm_release" "kong_data_plane" {
  name       = "kong-data-plane"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = "2.38.0"
  namespace  = kubernetes_namespace.eks_kong.id

  values = [
    "${file("values-kong-data-plane.yaml")}"
  ]

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
}