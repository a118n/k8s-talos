variable "vm_spec" {
  type = map(object({
    cpu = number
    ram = number
    disks = map(object({
      size = number
    }))
  }))
}

variable "vm_image_path" {
  type        = string
  description = "Absolute path to the image used for VM provisioning"
  default     = "/var/lib/libvirt/images/talos.qcow2"
}

variable "talos_cluster_name" {
  type        = string
  description = "Name of the cluster"
  default     = "talos"
}

variable "talos_cluster_vip" {
  type        = string
  description = "Virtual IP address to be used as cluster endpoint"
  default     = "192.168.100.100"
}

variable "cilium_version" {
  type        = string
  description = "Version of Cilium CNI to install"
  default     = "1.16.1"
}
