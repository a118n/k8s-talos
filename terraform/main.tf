resource "libvirt_pool" "k8s" {
  name = "k8s"
  type = "dir"
  path = "/var/lib/libvirt/pools/k8s"
}

resource "libvirt_network" "k8s" {
  name      = "k8s"
  mode      = "nat"
  domain    = "k8s.internal"
  addresses = ["192.168.100.0/25"]
  autostart = true

  dns {
    enabled    = true
    local_only = true
  }

  dhcp {
    enabled = true
  }
}

module "k8s_cluster" {
  depends_on   = [libvirt_pool.k8s, libvirt_network.k8s]
  source       = "./modules/vm"
  for_each     = var.vm_spec
  vm_name      = "${each.key}.k8s.internal"
  pool_name    = libvirt_pool.k8s.name
  vm_memory    = each.value.ram
  vm_vcpus     = each.value.cpu
  image_path   = var.vm_image_path
  network_name = libvirt_network.k8s.name
  network_id   = libvirt_network.k8s.id
  disks        = each.value.disks
}
