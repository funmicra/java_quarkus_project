
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "ciuser" {}
variable "cipassword" {}

variable "vm_count" {
 default = 1
}

variable "ssh_keys_file" {
  description = "Path to SSH public key file"
  type        = string
}

variable "vmid" {
  default = 9000
}

variable "base_name" {
  default = "java-quarkus"
}

variable "vm_template_id" {
  default = 1200
}

variable "target_node" {
  default = "Dell-Optiplex"
}