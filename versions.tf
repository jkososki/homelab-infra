terraform {
  required_version = ">= v1.13.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "~>3.3.0"
    }
  }
}
