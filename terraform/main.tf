# --- Control Plane Node ---

resource "proxmox_vm_qemu""ctrl-plane" {
  count       = 1
  vmid        = 1201
  onboot      = true
  vm_state    = "running"
  agent       = 1
  name        = "ctrl-plane"
  target_node = "Dell-Optiplex"
  clone_id    = 1200
  full_clone  = true
  memory      = 2048
  scsihw      = "virtio-scsi-single"
  boot        = "order=scsi0;ide2;net0"
  bootdisk    = "scsi0"
  os_type     =  "cloud-init"

  # Cloud-Init configuration
  ciuser       = var.ciuser
  cipassword   = var.cipassword
  ciupgrade    = true
  sshkeys = file(var.ssh_keys_file)
  ipconfig0  = "ip=192.168.88.90/25,gw=192.168.88.1"
  searchdomain = "local"
  nameserver   = "8.8.8.8 1.1.1.1"
  skip_ipv6 = true
  automatic_reboot = true
  #cicustom = file("./user-data.yaml")

  # CPU configuration
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }


  # Serial Block
  serial {
    id = 0
    type = "socket"
  }

  # VGA configuration
  vga {
    type = "serial0"
  }
  
  # Disk configuration
  disk {
    slot     = "scsi0"
    type     = "disk"
    storage  = "VMs"
    size     = "32G"
  }

  efidisk {
    efitype = "4m"
    storage = "VMs"
  }

  # cloudinit disk
  disk {
  slot    = "ide2"
  type    = "cloudinit"
  storage = "VMs"
  size    = "4G" 
 }

  # Network adapter
  network {
    id    = 0
    model = "virtio"
    bridge = "vmbr0"
  }

}

# --- Worker Nodes ---

resource "proxmox_vm_qemu""workers" {
  count       = var.vm_count
  vmid        = 1201 + "${count.index + 1}"
  onboot      = true
  vm_state    = "running"
  agent       = 1
  name        = "worker-${count.index + 1}"
  target_node = "Dell-Optiplex"
  clone_id    = 1200
  full_clone  = true
  memory      = 2048
  scsihw      = "virtio-scsi-single"
  boot        = "order=scsi0;ide2;net0"
  bootdisk    = "scsi0"
  os_type     =  "cloud-init"

  # Cloud-Init configuration
  ciuser       = var.ciuser
  cipassword   = var.cipassword
  ciupgrade    = true
  sshkeys = file(var.ssh_keys_file)
  ipconfig0  = "ip=192.168.88.${90 + count.index +1}/25,gw=192.168.88.1"
  searchdomain = "local"
  nameserver   = "8.8.8.8 1.1.1.1"
  skip_ipv6 = true
  automatic_reboot = true
  #cicustom = file("./user-data.yaml")

  # CPU configuration
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }


  # Serial Block
  serial {
    id = 0
    type = "socket"
  }

  # VGA configuration
  vga {
    type = "serial0"
  }
  
  # Disk configuration
  disk {
    slot     = "scsi0"
    type     = "disk"
    storage  = "VMs"
    size     = "32G"
  }

  efidisk {
    efitype = "4m"
    storage = "VMs"
  }

  # cloudinit disk
  disk {
  slot    = "ide2"
  type    = "cloudinit"
  storage = "VMs"
  size    = "4G" 
 }

  # Network adapter
  network {
    id    = 0
    model = "virtio"
    bridge = "vmbr0"
  }

}