variable pm_api_token_id {
    type = string
    default = ""
}
variable pm_fqdn {
    type = string
    default = ""
}
variable pm_api_token_secret{
    type = string
    default = ""
}
variable "fedora_root_fs_image_url" {
    type = string 
    default = "https://images.linuxcontainers.org/images/fedora/42/arm64/cloud/20250916_20:57/rootfs.tar.xz"
} 