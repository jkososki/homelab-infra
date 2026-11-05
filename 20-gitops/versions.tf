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
  }
}

provider "github" {
  owner = local.apps_repo.owner
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
