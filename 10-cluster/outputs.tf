output "talosconfig" {
  description = "Talos client configuration for use with talosctl."
  value       = module.cluster.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for the new cluster."
  value       = module.cluster.kubeconfig
  sensitive   = true
}

output "controlplane_nodes" {
  description = "Control plane node info."
  value       = module.cluster.controlplane_nodes
}

output "worker_nodes" {
  description = "Worker node info."
  value       = module.cluster.worker_nodes
}
