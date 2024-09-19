locals {
  workers = {
    for vm in module.k8s_cluster : vm.vm_name => vm.vm_ip_address if strcontains(vm.vm_name, "worker")
  }

  control_planes = {
    for vm in module.k8s_cluster : vm.vm_name => vm.vm_ip_address if strcontains(vm.vm_name, "control-plane")
  }
}

resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  depends_on           = [module.k8s_cluster]
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [module.k8s_cluster["control-plane-01"].vm_ip_address, module.k8s_cluster["control-plane-02"].vm_ip_address, module.k8s_cluster["control-plane-03"].vm_ip_address]

}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.talos_cluster_vip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
        network = {
          interfaces = [{
            deviceSelector = {
              busPath = "0*"
            }
            dhcp = true
            vip = {
              ip = var.talos_cluster_vip
            }
          }]
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  depends_on                  = [module.k8s_cluster]
  for_each                    = local.control_planes
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  node                        = each.value
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.key
          # domainname = "k8s.internal"
        }
      }
    })
  ]
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${var.talos_cluster_vip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = module.k8s_cluster["control-plane-01"].vm_ip_address
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on                  = [module.k8s_cluster, talos_machine_bootstrap.bootstrap]
  for_each                    = local.workers
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  node                        = each.value
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.key
          # domainname = "k8s.internal"
        }
      }
    })
  ]
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = module.k8s_cluster["control-plane-01"].vm_ip_address
}

resource "local_file" "kubeconfig" {
  depends_on      = [talos_machine_bootstrap.bootstrap]
  content         = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename        = pathexpand("~/.kube/config")
  file_permission = "0600"
}

resource "local_file" "talosconfig" {
  depends_on      = [talos_machine_bootstrap.bootstrap]
  content         = data.talos_client_configuration.talosconfig.talos_config
  filename        = pathexpand("~/.talos/config")
  file_permission = "0600"
}


# data "talos_cluster_health" "health" {
#   depends_on           = [talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply, talos_machine_bootstrap.bootstrap]
#   client_configuration = data.talos_client_configuration.talosconfig.client_configuration
#   control_plane_nodes  = [module.k8s_cluster["control-plane-01"].vm_ip_address, module.k8s_cluster["control-plane-02"].vm_ip_address, module.k8s_cluster["control-plane-03"].vm_ip_address]
#   worker_nodes         = [module.k8s_cluster["worker-01"].vm_ip_address, module.k8s_cluster["worker-02"].vm_ip_address, module.k8s_cluster["worker-03"].vm_ip_address]
#   endpoints            = data.talos_client_configuration.talosconfig.endpoints
#   timeouts = {
#     read = "10m"
#   }
# }
