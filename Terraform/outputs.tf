output "vm_names" {
  value = concat(
    [for vm in proxmox_vm_qemu.Eu_Dy : vm.name],
#    [for vm in proxmox_vm_qemu.k8s_Nodes : vm.name]
  )
}

output "vm_ids" {
  value = concat(
    [for vm in proxmox_vm_qemu.Eu_Dy : vm.vmid],
#    [for vm in proxmox_vm_qemu.k8s_Nodes : vm.vmid]
  )
}