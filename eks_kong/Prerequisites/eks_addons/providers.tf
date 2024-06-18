provider "aws" {
  region  = var.region
  profile = "ac-guru"
  default_tags {
    tags = {
      environment = var.environment
      purpose     = "Kong Demo"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

#provider "tls" {}