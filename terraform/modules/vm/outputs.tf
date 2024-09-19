output "vm_name" {
  description = "Name of created VM"
  value       = libvirt_domain.vm_domain.name
}

output "vm_ip_address" {
  description = "The IP address of created VM"
  value       = libvirt_domain.vm_domain.network_interface[0].addresses[0]
}
