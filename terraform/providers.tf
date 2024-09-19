terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    talos = {
      source = "siderolabs/talos"
    }
    local = {
      source = "hashicorp/local"
    }
    helm = {
      source = "hashicorp/helm"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
