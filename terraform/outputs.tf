output "vm_names" {
  value = concat(
    [for vm in proxmox_vm_qemu.EuroDyn : vm.name],
  )
}

output "vm_ids" {
  value = concat(
    [for vm in proxmox_vm_qemu.EuroDyn : vm.vmid],
  )
}