

variable "pm_api_token_id"{
  default = "PROXMOX_TOKEN_ID"
}
variable "pm_api_token_secret"{
  default = "PROXMOX_TOKEN_SECRET"  
}

variable "vm_count" {
 default = 2
}

variable "vmid" {
  default = 9000
}

variable "base_name" {
  default = "EuroDyn"
}

variable "vm_template_id" {
  default = 1200
}

variable "target_node" {
  default = "pve_hostname"
}

variable "ciuser" {
  default = "funmicra"
}

variable "cipassword" {
  default = "H84zzoMc"
}

variable "ipconfig" {
  default = "ip=dhcp"
}

#variable "ipconfig1" {
#  default = "ip=192.168.88.${60 + count.index}/25,gw=192.168.88.1"
#}