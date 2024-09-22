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


resource "tls_private_key" "talos_ca_private_key" {
  algorithm = "RSA"
}

resource "local_file" "talos_ca_key" {
  content  = tls_private_key.talos_ca_private_key.private_key_pem
  filename = "${path.module}/certs/talos-ca.key"
}

resource "tls_self_signed_cert" "talos_ca_cert" {
  private_key_pem   = tls_private_key.talos_ca_private_key.private_key_pem
  is_ca_certificate = true
  subject {
    country             = "RU"
    province            = "Moscow"
    locality            = "Moscow"
    common_name         = "Talos Root CA"
    organization        = "Talos"
    organizational_unit = "Talos"
  }

  validity_period_hours = 43800 //  1825 days or 5 years

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "talos_ca_cert" {
  content  = tls_self_signed_cert.talos_ca_cert.cert_pem
  filename = "${path.module}/certs/talos-ca.crt"
}
