locals {
  # Configuration composition
  base_content     = file(var.base_config_path)
  override_content = file(var.override_config_path)

  base_config     = yamldecode(trimspace(local.base_content) == "" ? "{}" : local.base_content)
  override_config = yamldecode(trimspace(local.override_content) == "" ? "{}" : local.override_content)
}

module "inputs" {
  source = "../modules/inputs"

  config = provider::deepmerge::mergo(local.base_config, local.override_config)
}

locals {
  apps_repo = module.inputs.apps_repository
  apps_init = module.inputs.apps_init
}

data "github_repository_file" "base_values" {
  for_each = local.apps_init

  repository = local.apps_repo.repo
  branch     = local.apps_repo.branch
  file       = each.value.values.base
  lifecycle {
    postcondition {
      condition     = self.content != null
      error_message = "base_values file for '${each.key}' not found."
    }
  }
}

data "github_repository_file" "override_values" {
  for_each = local.apps_init

  repository = local.apps_repo.repo
  branch     = local.apps_repo.branch
  file       = each.value.values.override

  lifecycle {
    postcondition {
      condition     = self.content != null
      error_message = "override_values file for '${each.key}' not found."
    }
  }
}

locals {
  gateway_api = local.apps_init.gateway_api
}

resource "helm_release" "gateway_api" {
  depends_on = [
    data.github_repository_file.base_values,
    data.github_repository_file.override_values
  ]

  name             = local.gateway_api.release_name
  namespace        = local.gateway_api.namespace
  create_namespace = true
  repository       = local.gateway_api.repository
  chart            = local.gateway_api.chart
  version          = local.gateway_api.version
  wait             = true
  skip_crds        = false

  values = [
    data.github_repository_file.base_values["gateway_api"].content,
    data.github_repository_file.override_values["gateway_api"].content
  ]

  set = []

  lifecycle {
    ignore_changes  = all
    prevent_destroy = false
  }
}

locals {
  cluster = module.inputs.cluster
  cilium  = local.apps_init.cilium
}

resource "helm_release" "cilium" {
  depends_on = [
    helm_release.gateway_api
  ]

  name             = local.cilium.release_name
  namespace        = local.cilium.namespace
  create_namespace = true
  repository       = local.cilium.repository
  chart            = local.cilium.chart
  version          = local.cilium.version
  wait             = true
  skip_crds        = false

  values = [
    data.github_repository_file.base_values["cilium"].content,
    data.github_repository_file.override_values["cilium"].content
  ]

  set = [
    {
      name  = "k8sServiceHost"
      value = local.cluster.cluster_vip
    },
    {
      name  = "k8sServicePort"
      value = local.cluster.service_port
    }
  ]
  lifecycle {
    ignore_changes  = all
    prevent_destroy = false
  }
}

locals {
  cilium_resources = local.apps_init.cilium_resources
}
resource "helm_release" "cilium_resources" {
  depends_on = [
    helm_release.cilium
  ]

  name             = local.cilium_resources.release_name
  namespace        = local.cilium_resources.namespace
  create_namespace = true
  repository       = local.cilium_resources.repository
  chart            = local.cilium_resources.chart
  version          = local.cilium_resources.version
  wait             = true

  values = [
    data.github_repository_file.base_values["cilium_resources"].content,
    data.github_repository_file.override_values["cilium_resources"].content
  ]

  set = [
    {
      name  = "manifests.gateway.spec.infrastructure.annotations.lbipam\\.cilium\\.io/ips"
      value = local.cluster.ingress_ip
    }
  ]

  lifecycle {
    ignore_changes  = all
    prevent_destroy = false
  }
}

locals {
  argocd = local.apps_init.argocd
}

resource "helm_release" "argocd" {
  depends_on = [
    helm_release.cilium_resources
  ]

  name             = local.argocd.release_name
  namespace        = local.argocd.namespace
  create_namespace = true
  repository       = local.argocd.repository
  chart            = local.argocd.chart
  version          = local.argocd.version
  wait             = true

  values = [
    data.github_repository_file.base_values["argocd"].content,
    data.github_repository_file.override_values["argocd"].content
  ]

  set = []

  lifecycle {
    ignore_changes  = all
    prevent_destroy = false
  }
}

locals {
  homelab = local.apps_init.homelab
}

resource "helm_release" "homelab" {
  depends_on = [
    helm_release.argocd
  ]

  name             = local.homelab.release_name
  namespace        = local.homelab.namespace
  create_namespace = true
  repository       = local.homelab.repository
  chart            = local.homelab.chart
  version          = local.homelab.version
  wait             = true

  values = [
    data.github_repository_file.base_values["homelab"].content,
    data.github_repository_file.override_values["homelab"].content
  ]

  set = []

  lifecycle {
    ignore_changes  = all
    prevent_destroy = false
  }
}
