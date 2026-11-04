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
