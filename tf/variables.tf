variable "pm_api_token_id" {
  type      = string
  sensitive = true
}
variable "pm_fqdn" {
  type = string
}
variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_user_realm" {
  type = string
  sensitive = true
}

variable "pm_node" {
  type = string
  sensitive = true
}

variable "pm_ssh_key" {
  type = string
  sensitive = true
}

variable "pm_ssh_user" {
  type = string
  sensitive = true
}

variable "pm_ssh_host" {
  type = string
  sensitive = true
}

variable "root_fs_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"
}

variable "pm_datastore" {
  type    = string
  default = "local"
}

variable "root_fs_image_name" {
  type    = string
  default = "ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"
}

variable "github_username" {
  type    = string
  default = "arjf"
}