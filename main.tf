locals {
  # Configuration composition
  base_content     = file(var.base_config_path)
  override_content = file(var.override_config_path)

  base_config     = yamldecode(trimspace(local.base_content) == "" ? "{}" : local.base_content)
  override_config = yamldecode(trimspace(local.override_content) == "" ? "{}" : local.override_content)

  config = provider::deepmerge::mergo(local.base_config, local.override_config)
}

locals {
  # Day-Zero helm deployment configurations

  # cilium_version = local.config.cilium.version
  apps_repo = local.config.apps_repository
  apps      = local.config.apps_init
}

data "github_repository_file" "base_values" {
  for_each = local.apps

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
  for_each = local.apps

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

data "helm_template" "this" {
  for_each = local.apps

  name             = each.key
  namespace        = each.value.namespace
  create_namespace = true
  chart            = each.value.chart
  version          = each.value.version
  kube_version     = local.config.cluster.kubernetes_version

  values = [
    data.github_repository_file.base_values[each.key].content,
    data.github_repository_file.override_values[each.key].content
  ]
}

locals {
  manifest = join("\n---\n", [
    for k, v in data.helm_template.this : v.manifest
  ])
}

# Day-zero manifests are rendered once and frozen in state. Later changes to the
# base/override values (or chart version) must not alter the cluster module;
# the app-of-apps takes over lifecycle management after bootstrap.
resource "terraform_data" "day_zero_manifest" {
  input = local.manifest

  lifecycle {
    ignore_changes = [input]
  }
}

module "cluster" {
  source = "git@github.com:jkososki/terraform-proxmox-talos-k8s.git?ref=v0.0.3"

  kubernetes_version = local.config.cluster.kubernetes_version
  talos_version      = local.config.cluster.talos_version
  iso_datastore      = local.config.cluster.iso_datastore
  cluster_name       = local.config.cluster.cluster_name
  gateway_ip         = local.config.cluster.gateway_ip
  cluster_vip        = local.config.cluster.cluster_vip
  pve_hosts          = local.config.cluster.pve_hosts
  controlplane_nodes = local.config.cluster.controlplane_nodes
  worker_nodes       = local.config.cluster.worker_nodes
  inline_manifests   = terraform_data.day_zero_manifest.output
}
