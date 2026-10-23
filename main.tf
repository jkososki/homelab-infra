module "cluster" {
  source = "git@github.com:jkososki/terraform-proxmox-talos-k8s.git?ref=v0.0.1"

  iso_datastore = "local"
  cluster_name  = "homelab"
  gateway_ip    = "192.168.144.1"
  cluster_vip   = "192.168.144.220"

  pve_hosts = {
    "pve01" = {
      name = "pve01"
    }
    "pve02" = {
      name = "pve02"
    }
    "pve03" = {
      name = "pve03"
    }
  }

  controlplane_nodes = {
    "cp1" = {
      core_count = 2
      disk_gb    = 20
      memory_mb  = 4 * 1024
      node_ip    = "192.168.144.221"
      pve_host   = "pve01"
    }
    "cp2" = {
      core_count = 2
      disk_gb    = 20
      memory_mb  = 4 * 1024
      node_ip    = "192.168.144.222"
      pve_host   = "pve02"
    }
    "cp3" = {
      core_count = 2
      disk_gb    = 20
      memory_mb  = 4 * 1024
      node_ip    = "192.168.144.223"
      pve_host   = "pve03"
    }
  }

  worker_nodes = {
    "w1" = {
      core_count    = 8
      disk_gb       = 20
      extra_disk_gb = 500
      memory_mb     = 48 * 1024
      node_ip       = "192.168.144.231"
      pve_host      = "pve01"
    }
    "w2" = {
      core_count    = 8
      disk_gb       = 20
      extra_disk_gb = 500
      memory_mb     = 48 * 1024
      node_ip       = "192.168.144.232"
      pve_host      = "pve02"
    }
    "w3" = {
      core_count    = 14
      disk_gb       = 20
      extra_disk_gb = 500
      memory_mb     = 48 * 1024
      node_ip       = "192.168.144.233"
      pve_host      = "pve03"
    }
  }
}



# locals {
#   cp_nodes = sort(keys(var.controlplane_nodes))
# }

# data "helm_template" "cilium" {
#   chart        = "oci://quay.io/cilium/charts/cilium"
#   kube_version = var.kubernetes_version
#   name         = "cilium"
#   namespace    = "kube-system"
#   version      = var.cilium_version
#   include_crds = true
#   skip_tests   = true

#   values = [yamlencode({
#     k8sServiceHost       = var.controlplane_nodes[local.cp_nodes[0]].node_ip
#     k8sServicePort       = 6443
#     kubeProxyReplacement = true

#     cgroup = {
#       autoMount = { enabled = false }
#       hostRoot  = "/sys/fs/cgroup"
#     }

#     gatewayAPI = {
#       enabled = true
#     }

#     ipam = {
#       mode = "kubernetes"
#     }

#     l2announcements = {
#       enabled = true
#     }

#     operator = {
#       replicas = min(length(local.cp_nodes), 2)
#     }

#     securityContext = {
#       capabilities = {
#         ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
#         cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
#       }
#     }
#   })]
# }
