variable "config" {
  type = object({
    apps_repository = object({
      owner  = string
      repo   = string
      branch = string
    })
    apps_init = map(object({
      release_name = string
      version      = string
      repository   = string
      chart        = string
      namespace    = string
      values = object({
        base     = string
        override = string
      })
    }))
    cluster = object({
      talos_version       = string
      kubernetes_version  = string
      iso_datastore       = string
      cluster_name        = string
      gateway_ip          = string
      ingress_ip          = string
      gateway_api_version = string
      cluster_vip         = string
      service_port        = number
      pve_hosts = map(object({
        name = string
      }))
      controlplane_nodes = map(object({
        core_count    = number
        disk_gb       = number
        extra_disk_gb = optional(number)
        memory_mb     = number
        node_ip       = string
        pve_host      = string
      }))
      worker_nodes = map(object({
        core_count    = number
        disk_gb       = number
        extra_disk_gb = optional(number)
        memory_mb     = number
        node_ip       = string
        pve_host      = string
      }))
    })
  })
}
