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
