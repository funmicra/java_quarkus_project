

variable "pm_api_token_id"{
  default = "Terraform@pam!Terraform"
}
variable "pm_api_token_secret"{
  default = "49c89069-ef74-4ab6-92b4-e6455cc8897e"  
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