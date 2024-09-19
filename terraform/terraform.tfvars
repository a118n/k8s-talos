vm_spec = {
  "control-plane-01" = {
    cpu   = 2
    ram   = 2048
    disks = {}
  },
  "control-plane-02" = {
    cpu   = 2
    ram   = 2048
    disks = {}
  },
  "control-plane-03" = {
    cpu   = 2
    ram   = 2048
    disks = {}
  },
  "worker-01" = {
    cpu = 2
    ram = 2048
    disks = {
      "data-01" = { size = 53687091200 }
    }
  },
  "worker-02" = {
    cpu = 2
    ram = 2048
    disks = {
      "data-01" = { size = 53687091200 }
    }
  },
  "worker-03" = {
    cpu = 2
    ram = 2048
    disks = {
      "data-01" = { size = 53687091200 }
    }
  }
}
