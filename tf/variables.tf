variable pm_api_token_id {
    type = string
    sensitive = true
}
variable pm_fqdn {
    type = string
}
variable pm_api_token_secret{
    type = string
    sensitive = true
}
variable "fedora_root_fs_image_url" {
    type = string 
    default = "https://images.linuxcontainers.org/images/fedora/42/amd64/cloud/20250916_20:57/rootfs.tar.xz"
} 

variable "pm_datastore" {
    type = string
    default = "local"   
}

variable "fedora_root_fs_image_name" {
    type = string
    default = "fedora-42-cloud_20250916_amd64.tar.xz"
}

variable "github_username" {
    type = string
    default = "arjf"
}