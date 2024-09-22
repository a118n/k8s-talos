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

variable "argocd_version" {
  type        = string
  description = "Version of Argo CD to install"
  default     = "7.6.0"
}

variable "metallb_version" {
  type        = string
  description = "Version of MetalLB to install"
  default     = "0.14.8"
}

variable "ingress_nginx_version" {
  type        = string
  description = "Version of Ingress NGINX to install"
  default     = "4.11.2"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install"
  default     = "v1.15.3"
}
