# Deploy Talos K8S cluster on KVM (libvirt) using Terraform

## Prepare the host
Some preliminary steps are required on the host. Fedora, in this example.

### Disable SELinux
```shell
sudo grubby --update-kernel ALL --args selinux=0
```

### Install libvirt
```shell
sudo dnf install -y @virtualization
sudo usermod -aG libvirt $USER
echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc && source ~/.bashrc
sudo systemctl enable --now libvirtd
```

### Install libvirt hook
In order to correctly resolve DNS names of VMs while using systemd-resolved we need to install libvirt hook:
```shell
sudo dnf install -y make publicsuffix-list
sudo mkdir -p /etc/libvirt/hooks/network.d
git clone https://github.com/tprasadtp/libvirt-systemd-resolved.git
cd libvirt-systemd-resolved
sudo make install
sudo systemctl restart libvirtd.service
```

### Prepare Talos image
First, let's head to [Talos Image Factory](https://factory.talos.dev) and generate custom image:

- Hardware Type: Bare-metal Machine
- Machine Architecture: amd64
- System Extensions:
  - iscsi-tools
  - qemu-guest-agent
  - util-linux-tools

- Extra Kernel Args:
  - ipv6.disable=1
  - mitigations=off (OPTIONAL)

Download disk image in RAW format and then let's prepare it for use with libvirt:

```shell
xz --decompress metal-amd64-secureboot.raw.xz
qemu-img convert -f raw -O qcow2 metal-amd64-secureboot.raw talos.qcow2
qemu-img resize talos.qcow2 30G
sudo mv talos.qcow2 /var/lib/libvirt/images/talos.qcow2
```

## Terraform
Now we can deploy our infrastructure using Terraform:
```shell
cd terraform
terraform init
terraform apply -auto-approve
```

## Talos
Verify that all nodes are joined and working:
```shell
talosctl get members -n 192.168.100.100
```

Check that all services are healthy:
```shell
talosctl -n 192.168.100.100 health
```

Verify kubectl is working:
```shell
kubectl cluster-info
kubectl get nodes -o wide
```
