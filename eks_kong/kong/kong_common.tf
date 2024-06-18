# This approach is only acceptable for Demo purposes. Please consider other way for production deployments

resource "tls_private_key" "kong" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "kong" {
  private_key_pem = tls_private_key.kong.private_key_pem

  validity_period_hours = 26280

  early_renewal_hours = 3

  allowed_uses = [
    "any_extended",
    #    "key_encipherment",
    #    "digital_signature",
    #    "server_auth",
  ]

  subject {
    common_name = "kong_clustering"
  }
}

resource "kubernetes_namespace" "eks_kong" {
  metadata {
    name = "kong"
    #    name = "${var.environment}-kong"
  }
}

resource "kubernetes_secret" "kong_tls" {
  metadata {
    name      = "kong-cluster-cert"
    namespace = kubernetes_namespace.eks_kong.id
  }

  data = {

    "tls.crt" = file("TEST/tls.crt")
    "tls.key" = file("TEST/tls.key")
    #  "tls.crt" = tls_self_signed_cert.kong.cert_pem
    #  "tls.key" = tls_private_key.kong.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_secret" "kong_license" {
  metadata {
    name      = "kong-enterprise-license"
    namespace = kubernetes_namespace.eks_kong.id
  }

  data = {
    "license" = "'{}'"
  }

  type = "Opaque"
}