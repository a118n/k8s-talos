terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-beta.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
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

provider "kubectl" {
  config_path = "~/.kube/config"
}
