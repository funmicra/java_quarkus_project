output "vm_names" {
  value = concat(
    [for vm in proxmox_vm_qemu.ctrl-plane : vm.name],
    [for vm in proxmox_vm_qemu.workers : vm.name]
  )
}

output "vm_ids" {
  value = concat(
    [for vm in proxmox_vm_qemu.ctrl-plane : vm.vmid],
    [for vm in proxmox_vm_qemu.wokers : vm.vmid]
  )
}