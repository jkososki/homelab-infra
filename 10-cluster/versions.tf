terraform {
  required_version = ">= v1.13.1"

  backend "local" {}

  required_providers {
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.0"
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
