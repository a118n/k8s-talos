resource "libvirt_volume" "os_volume" {
  name   = "${var.vm_name}-os.qcow2"
  source = var.image_path
  pool   = var.pool_name
  format = "qcow2"
}

resource "libvirt_volume" "data_volume" {
  for_each = var.disks
  name     = "${var.vm_name}-${each.key}.qcow2"
  pool     = var.pool_name
  format   = "qcow2"
  size     = each.value.size
}

resource "libvirt_domain" "vm_domain" {
  lifecycle {
    ignore_changes = [
      nvram,
    ]
  }
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpus
  cpu {
    mode = "host-passthrough"
  }
  video {
    type = "virtio"
  }
  qemu_agent = true
  autostart  = false

  firmware = "/usr/share/OVMF/OVMF_CODE.fd"
  machine  = "q35"

  disk {
    volume_id = libvirt_volume.os_volume.id
  }

  dynamic "disk" {
    for_each = libvirt_volume.data_volume
    content {
      volume_id = disk.value.id
    }
  }
  network_interface {
    hostname       = var.vm_name
    network_name   = var.network_name
    network_id     = var.network_id
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
