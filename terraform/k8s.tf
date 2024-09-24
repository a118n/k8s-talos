resource "time_sleep" "wait_2min" {
  depends_on      = [talos_machine_bootstrap.bootstrap]
  create_duration = "2m"
}

resource "helm_release" "cilium" {
  depends_on = [time_sleep.wait_2min, local_file.kubeconfig]
  repository = "https://helm.cilium.io/"
  name       = "cilium"
  chart      = "cilium"
  namespace  = "kube-system"
  version    = var.cilium_version
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }
  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }
  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }
  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }
  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }
  set {
    name  = "k8sServicePort"
    value = "7445"
  }
  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }
  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }
  set {
    name  = "hubble.ui.frontend.server.ipv6.enabled"
    value = "false"
  }
}

resource "kubectl_manifest" "metallb_ns" {
  depends_on = [helm_release.cilium, local_file.kubeconfig]
  yaml_body  = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: metallb
  labels:
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/warn: privileged
YAML
}

resource "helm_release" "metallb" {
  depends_on = [kubectl_manifest.metallb_ns, local_file.kubeconfig]
  repository = "https://metallb.github.io/metallb"
  name       = "metallb"
  chart      = "metallb"
  namespace  = "metallb"
  version    = var.metallb_version
  set {
    name  = "speaker.frr.enabled"
    value = "false"
  }
  set {
    name  = "frrk8s.enabled"
    value = "false"
  }
}

resource "time_sleep" "wait_30sec_metallb" {
  depends_on      = [helm_release.metallb]
  create_duration = "30s"
}

resource "kubectl_manifest" "metallb_pool" {
  depends_on = [time_sleep.wait_30sec_metallb, helm_release.metallb, local_file.kubeconfig]
  yaml_body  = <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: talos
  namespace: metallb
spec:
  addresses:
  - 192.168.100.101-192.168.100.110
YAML
}

resource "kubectl_manifest" "metallb_advertisement" {
  depends_on = [kubectl_manifest.metallb_pool, local_file.kubeconfig]
  yaml_body  = <<YAML
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: talos
  namespace: metallb
YAML
}

resource "helm_release" "ingress_nginx" {
  depends_on       = [kubectl_manifest.metallb_advertisement, local_file.kubeconfig]
  repository       = "https://kubernetes.github.io/ingress-nginx"
  name             = "ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = var.ingress_nginx_version
  set {
    name  = "controller.extraArgs.enable-ssl-passthrough"
    value = ""
  }
  set {
    name  = "controller.service.nodePorts.http"
    value = "30080"
  }
  set {
    name  = "controller.service.nodePorts.https"
    value = "30433"
  }
}

resource "helm_release" "cert_manager" {
  depends_on       = [helm_release.cilium, local_file.kubeconfig]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_version
  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "kubectl_manifest" "ca_secret" {
  depends_on = [helm_release.cert_manager, local_file.kubeconfig]
  yaml_body  = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ca-key-pair
  namespace: cert-manager
data:
  tls.crt: ${base64encode(tls_self_signed_cert.talos_ca_cert.cert_pem)}
  tls.key: ${base64encode(tls_private_key.talos_ca_private_key.private_key_pem)}
YAML
}

resource "kubectl_manifest" "ca_issuer" {
  depends_on = [kubectl_manifest.ca_secret, local_file.kubeconfig]
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: ca-key-pair
YAML
}

resource "helm_release" "argocd" {
  depends_on       = [helm_release.cilium, local_file.kubeconfig]
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argo-cd"
  create_namespace = true
  version          = var.argocd_version
}
