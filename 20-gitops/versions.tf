terraform {
  required_version = ">= v1.13.1"

  backend "local" {}

  required_providers {
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>3.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6.3"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
  }
}

provider "github" {
  owner = local.apps_repo.owner
}

locals {
  kubeconfig = yamldecode(module.cluster.kubeconfig)
}

provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
  }
}
