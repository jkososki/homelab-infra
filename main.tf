locals {
  base_content     = file(var.base_config_path)
  override_content = file(var.override_config_path)

  base_config     = yamldecode(trimspace(local.base_content) == "" ? "{}" : local.base_content)
  override_config = yamldecode(trimspace(local.override_content) == "" ? "{}" : local.override_content)

  config = provider::deepmerge::mergo(local.base_config, local.override_config)
}

module "cluster" {
  source = "git@github.com:jkososki/terraform-proxmox-talos-k8s.git?ref=v0.0.2"

  kubernetes_version = local.config.cluster.kubernetes_version
  talos_version      = local.config.cluster.talos_version
  iso_datastore      = local.config.cluster.iso_datastore
  cluster_name       = local.config.cluster.cluster_name
  gateway_ip         = local.config.cluster.gateway_ip
  cluster_vip        = local.config.cluster.cluster_vip
  pve_hosts          = local.config.cluster.pve_hosts
  controlplane_nodes = local.config.cluster.controlplane_nodes
  worker_nodes       = local.config.cluster.worker_nodes
}

# locals {
#   cp_nodes = sort(keys(var.controlplane_nodes))
# }

locals {
  cilium_version = local.config.cilium.version
}

resource "helm_release" "cilium" {
  depends_on = [
    module.cluster
  ]

  chart     = "oci://quay.io/cilium/charts/cilium"
  name      = "cilium"
  namespace = "kube-system"
  version   = local.cilium_version

  values = [yamlencode({
    k8sServiceHost       = values(local.config.cluster.controlplane_nodes)[0].node_ip
    k8sServicePort       = 6443
    kubeProxyReplacement = true

    cgroup = {
      autoMount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }

    gatewayAPI = {
      enabled = true
    }

    ipam = {
      mode = "kubernetes"
    }

    l2announcements = {
      enabled = true
    }

    operator = {
      replicas = min(length(local.config.cluster.controlplane_nodes), 2)
    }

    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }
  })]
}
