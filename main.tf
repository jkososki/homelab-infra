locals {
  # Configuration composition
  base_content     = file(var.base_config_path)
  override_content = file(var.override_config_path)

  base_config     = yamldecode(trimspace(local.base_content) == "" ? "{}" : local.base_content)
  override_config = yamldecode(trimspace(local.override_content) == "" ? "{}" : local.override_content)
}

module "inputs" {
  source = "./modules/inputs"

  config = provider::deepmerge::mergo(local.base_config, local.override_config)
}

locals {
  cluster = module.inputs.cluster
}

module "cluster" {
  source = "git@github.com:jkososki/terraform-proxmox-talos-k8s.git?ref=v0.0.3"

  kubernetes_version = local.cluster.kubernetes_version
  talos_version      = local.cluster.talos_version
  iso_datastore      = local.cluster.iso_datastore
  cluster_name       = local.cluster.cluster_name
  gateway_ip         = local.cluster.gateway_ip
  cluster_vip        = local.cluster.cluster_vip
  pve_hosts          = local.cluster.pve_hosts
  controlplane_nodes = local.cluster.controlplane_nodes
  worker_nodes       = local.cluster.worker_nodes
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
  cilium = local.apps_init.cilium
}

resource "helm_release" "cilium" {
  depends_on = [
    module.cluster,
    data.github_repository_file.base_values,
    data.github_repository_file.override_values
  ]

  name             = local.cilium.release_name
  namespace        = local.cilium.namespace
  create_namespace = true
  repository       = local.cilium.repository
  chart            = local.cilium.chart
  version          = local.cilium.version
  wait             = true

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
