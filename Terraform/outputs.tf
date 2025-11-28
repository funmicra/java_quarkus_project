output "vm_names" {
  value = concat(
    [for vm in proxmox_vm_qemu.EuroDyn : vm.name],
#    [for vm in proxmox_vm_qemu.k8s_Nodes : vm.name]
  )
}

output "vm_ids" {
  value = concat(
    [for vm in proxmox_vm_qemu.EuroDyn : vm.vmid],
#    [for vm in proxmox_vm_qemu.k8s_Nodes : vm.vmid]
  )
}