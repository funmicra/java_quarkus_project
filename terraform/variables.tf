
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "ciuser" {}
variable "cipassword" {}

variable "ssh_keys_file" {
  description = "Path to SSH public key file"
  type        = string
}