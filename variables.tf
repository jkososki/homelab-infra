variable "base_config_path" {
  description = "Path to the base configuration yaml."
  type        = string
  nullable    = false
}

variable "override_config_path" {
  description = "Path to the environment override yaml."
  type        = string
  nullable    = false
}

# variable "cilium_version" {
#   description = "Cilium Helm chart version to install as the CNI."
#   type        = string
#   default     = "1.20.3"
# }
