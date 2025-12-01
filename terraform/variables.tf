
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "ciuser" {}
variable "cipassword" {}
variable "ssh_keys_file" {}
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
  default = "Dell-Optiplex"
}