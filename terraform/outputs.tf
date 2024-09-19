# output "ip_addresses" {
#   description = "IP addresses of created VMs"
#   value       = values(module.k8s_cluster)[*].vm_ip_address
# }

output "vms_info" {
  description = "General information about created VMs"
  value = [
    for vm in module.k8s_cluster : {
      id = vm.vm_name
      ip = vm.vm_ip_address
    }
  ]
}

# output "control_planes" {
#   value = [
#     for vm in module.k8s_cluster : { id = vm.vm_name, ip = vm.vm_ip_address } if strcontains(vm.vm_name, "control-plane")
#   ]
# }

# output "workers" {
#   value = [
#     for vm in module.k8s_cluster : { id = vm.vm_name, ip = vm.vm_ip_address } if strcontains(vm.vm_name, "worker")
#   ]
# }

# output "talosconfig" {
#   value     = data.talos_client_configuration.talosconfig.talos_config
#   sensitive = true
# }

# output "kubeconfig" {
#   value     = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
#   sensitive = true
# }
